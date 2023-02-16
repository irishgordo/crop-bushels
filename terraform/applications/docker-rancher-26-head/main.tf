resource "harvester_network" "mgmt-vlan1-dr26-head" {
  name      = "mgmt-vlan1-dr26-head"
  namespace = "default"

  vlan_id = 1

  route_mode           = "auto"
  route_dhcp_server_ip = ""

  cluster_network_name = "mgmt"
}

resource "harvester_image" "ubuntu2204-jammy-dr26-head" {
  name      = "ubuntu-2204-dr26-head"
  namespace = "default"
  storage_class_name = "harvester-longhorn"
  display_name = "jammy-server-cloudimg-amd64-disk-kvm-dr26-head.img"
  source_type  = "download"
  url          = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64-disk-kvm.img"
}


resource "harvester_ssh_key" "dr26-head-ssh-key" {
  name      = "dr26-head-ssh-key"
  namespace = "default"

  public_key = var.SSH_KEY
}

locals {
  cloud_init_dr26-head = <<-EOT
    #cloud-config
    password: ${var.DR26_HEAD_VM_PW}
    chpasswd:
    expire: false
    ssh_pwauth: true
    package_update: true
    packages:
    - qemu-guest-agent
    - apt-transport-https
    - ca-certificates
    - curl
    - gnupg-agent
    - gnupg
    - lsb-release
    - software-properties-common
    - openssl
    runcmd:
    - - systemctl
        - enable
        - --now
        - qemu-guest-agent.service
    - curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
    - add-apt-repository "deb [arch=$(dpkg --print-architecture)]
        https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    - apt-get update -y
    - apt-get install -y docker-ce docker-ce-cli containerd.io
        docker-compose-plugin
    - systemctl enable --now qemu-guest-agent.service
    - systemctl enable docker
    - systemctl start docker
    - sysctl -w net.bridge.bridge-nf-call-iptables=1
    - sysctl --system
    - docker run -d --restart=unless-stopped -p 80:80 -p 443:443 --privileged rancher/rancher:v2.6-head
    ssh_authorized_keys:
      - ${var.SSH_KEY}
    EOT
}

resource "kubernetes_secret" "dr26-head-cloud-config-secret" {
  metadata {
    name      = "dr26-head-cc-secret"
    namespace = "default"
    labels = {
      "sensitive" = "false"
    }
  }
  data = {
    "userdata" = local.cloud_init_dr26-head
  }
}

resource "harvester_virtualmachine" "dr26-head-vm" {
  depends_on = [
    kubernetes_secret.dr26-head-cloud-config-secret
  ]
  name                 = var.DR26_HEAD_NAME
  namespace            = "default"
  restart_after_update = true

  description = "Docker based Rancher v2.6-head"
  tags = {
    ssh-user = "ubuntu"
  }

  cpu    = var.DR26_HEAD_DESIRED_CPU
  memory = var.DR26_HEAD_DESIRED_MEM

  efi         = true
  secure_boot = false

  run_strategy = "RerunOnFailure"
  hostname     = var.DR26_HEAD_NAME
  machine_type = "q35"

  ssh_keys = [
    harvester_ssh_key.dr26-head-ssh-key.id
  ]

  network_interface {
    name           = "nic-1"
    wait_for_lease = true
    model = "virtio"
    type = "bridge"
    network_name = harvester_network.mgmt-vlan1-dr26-head.id
  }

  disk {
    name       = "rootdisk"
    type       = "disk"
    size       = var.DR26_HEAD_DISK_SIZE
    bus        = "virtio"
    boot_order = 1

    image       = harvester_image.ubuntu2204-jammy-dr26-head.id
    auto_delete = true
  }

  cloudinit {
    user_data_secret_name = "dr26-head-cc-secret"
    network_data = ""
  }
}
