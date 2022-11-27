resource "harvester_network" "mgmt-vlan1-es" {
  name      = "mgmt-vlan1-es"
  namespace = "default"

  vlan_id = 1

  route_mode           = "auto"
  route_dhcp_server_ip = ""

  cluster_network_name = "mgmt"
}

resource "harvester_image" "ubuntu2204-jammy-es" {
  name      = "ubuntu-2204-jammy-es"
  namespace = "default"
  storage_class_name = "harvester-longhorn"
  display_name = "jammy-server-cloudimg-amd64-disk-kvm-es.img"
  source_type  = "download"
  url          = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64-disk-kvm.img"
}


resource "harvester_ssh_key" "es-ssh-key" {
  name      = "es-ssh-key"
  namespace = "default"

  public_key = var.SSH_KEY
}

locals {
  cloud_init_es = <<-EOT
    #cloud-config
    password: ${var.ES_VM_PW}
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
    - sysctl -w vm.max_map_count=262144
    - systemctl start docker
    - sysctl -w net.bridge.bridge-nf-call-iptables=1
    - sysctl --system
    - docker run -d --name elasticsearch -p 9200:9200 -p 9300:9300 -e xpack.security.enabled=false -e node.name=es01 -it docker.elastic.co/elasticsearch/elasticsearch:6.8.23
    - docker logs $(docker ps | tail -1 | sed -e 's/ .*$//g')
    ssh_authorized_keys:
      - ${var.SSH_KEY}
    EOT
}

resource "kubernetes_secret" "es-cloud-config-secret" {
  metadata {
    name      = "es-cc-secret"
    namespace = "default"
    labels = {
      "sensitive" = "false"
    }
  }
  data = {
    "userdata" = local.cloud_init_es
  } 
}

resource "harvester_virtualmachine" "es-vm" {
  depends_on = [
    kubernetes_secret.es-cloud-config-secret
  ]
  name                 = var.ES_NAME
  namespace            = "default"
  restart_after_update = true

  description = "Elasticsearch VM v6.8"
  tags = {
    ssh-user = "ubuntu"
  }

  cpu    = var.ES_DESIRED_CPU
  memory = var.ES_DESIRED_MEM

  efi         = true
  secure_boot = false

  run_strategy = "RerunOnFailure"
  hostname     = var.ES_NAME
  machine_type = "q35"

  ssh_keys = [
    harvester_ssh_key.es-ssh-key.id
  ]

  network_interface {
    name           = "nic-1"
    wait_for_lease = true
    model = "virtio"
    type = "bridge"
    network_name = harvester_network.mgmt-vlan1-es.id
  }

  disk {
    name       = "rootdisk"
    type       = "disk"
    size       = var.ES_DISK_SIZE
    bus        = "virtio"
    boot_order = 1

    image       = harvester_image.ubuntu2204-jammy-es.id
    auto_delete = true
  }

  cloudinit {
    user_data_secret_name = "es-cc-secret"
    network_data = ""
  }
}