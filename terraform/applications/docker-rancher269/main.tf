resource "harvester_network" "mgmt-vlan1-dr269" {
  name      = "mgmt-vlan1-dr269"
  namespace = "default"

  vlan_id = 1

  route_mode           = "auto"
  route_dhcp_server_ip = ""

  cluster_network_name = "mgmt"
}

resource "harvester_image" "ubuntu2204-jammy-dr269" {
  name      = "ubuntu-2204-dr269"
  namespace = "default"
  storage_class_name = "harvester-longhorn"
  display_name = "jammy-server-cloudimg-amd64-disk-kvm-dr269.img"
  source_type  = "download"
  url          = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64-disk-kvm.img"
}


resource "harvester_ssh_key" "dr269-ssh-key" {
  name      = "dr269-ssh-key"
  namespace = "default"

  public_key = var.SSH_KEY
}

locals {
  cloud_init_dr269 = <<-EOT
    #cloud-config
    password: ${var.DR269_VM_PW}
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
    - docker run -d --restart=unless-stopped -p 80:80 -p 443:443 --privileged rancher/rancher:v2.6.9
    ssh_authorized_keys:
      - ${var.SSH_KEY}
    EOT
}

resource "kubernetes_secret" "dr269-cloud-config-secret" {
  metadata {
    name      = "dr269-cc-secret"
    namespace = "default"
    labels = {
      "sensitive" = "false"
    }
  }
  data = {
    "userdata" = local.cloud_init_dr269
  } 
}

resource "harvester_virtualmachine" "dr269-vm" {
  depends_on = [
    kubernetes_secret.dr269-cloud-config-secret
  ]
  name                 = var.DR269_NAME
  namespace            = "default"
  restart_after_update = true

  description = "Docker based Rancher v2.6.9"
  tags = {
    ssh-user = "ubuntu"
  }

  cpu    = var.DR269_DESIRED_CPU
  memory = var.DR269_DESIRED_MEM

  efi         = true
  secure_boot = false

  run_strategy = "RerunOnFailure"
  hostname     = var.DR269_NAME
  machine_type = "q35"

  ssh_keys = [
    harvester_ssh_key.dr269-ssh-key.id
  ]

  network_interface {
    name           = "nic-1"
    wait_for_lease = true
    model = "virtio"
    type = "bridge"
    network_name = harvester_network.mgmt-vlan1-dr269.id
  }

  disk {
    name       = "rootdisk"
    type       = "disk"
    size       = var.DR269_DISK_SIZE
    bus        = "virtio"
    boot_order = 1

    image       = harvester_image.ubuntu2204-jammy-dr269.id
    auto_delete = true
  }

  cloudinit {
    user_data_secret_name = "dr269-cc-secret"
    network_data = ""
  }
}