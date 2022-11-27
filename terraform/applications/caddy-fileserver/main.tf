resource "harvester_network" "mgmt-vlan1-caddy" {
  name      = "mgmt-vlan1-caddy"
  namespace = "default"

  vlan_id = 1

  route_mode           = "auto"
  route_dhcp_server_ip = ""

  cluster_network_name = "mgmt"
}

resource "harvester_image" "ubuntu2204-jammy-caddy" {
  name      = "ubuntu-2204-jammy-caddy"
  namespace = "default"
  storage_class_name = "harvester-longhorn"
  display_name = "jammy-server-cloudimg-amd64-disk-kvm-caddy.img"
  source_type  = "download"
  url          = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64-disk-kvm.img"
}


resource "harvester_ssh_key" "caddy-ssh-key" {
  name      = "caddy-ssh-key"
  namespace = "default"

  public_key = var.SSH_KEY
}

locals {
  cloud_init_caddy = <<-EOT
    #cloud-config
    password: ${var.CADDY_VM_PW}
    chpasswd:
      expire: false
    ssh_pwauth: true
    package_update: true
    write_files:
      - path: /tmp/Caddyfile
        content: |
          :${var.CADDY_FILESERVER_PORT} {
            log {
              level DEBUG
            }
            root * /home/ubuntu/harvester-isos
            file_server browse
          }
        owner: ubuntu:ubuntu
    packages:
      - qemu-guest-agent
      - apt-transport-https
      - neovim
      - wget
      - ca-certificates
      - curl
      - gnupg-agent
      - gnupg
      - lsb-release
      - software-properties-common
      - coreutils
    runcmd:
      - - systemctl
        - enable
        - --now
        - qemu-guest-agent.service
      - apt install -y debian-keyring debian-archive-keyring apt-transport-https
      - >
        curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg
        --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
      - >
        curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' |
        sudo tee /etc/apt/sources.list.d/caddy-stable.list
      - apt update -y
      - apt install -y caddy
      - mkdir -p /home/ubuntu/harvester-isos
      - wget
        https://releases.rancher.com/harvester/master/harvester-master-amd64.iso
        -O /home/ubuntu/harvester-isos/harvester-master-amd64.iso
      - cp -v /tmp/grab-and-build-latest-master-head.sh /home/ubuntu
      - chmod +x /home/ubuntu/grab-and-build-latest-master-head.sh 
      - chown -v ubuntu:ubuntu /home/ubuntu/grab-and-build-latest-master-head.sh 
      - cd /home/ubuntu && ./grab-and-build-latest-master-head.sh
      - chown -Rv ubuntu:ubuntu /home/ubuntu/harvester-isos
      - systemctl stop caddy
      - systemctl enable caddy
      - systemctl daemon-reload
      - cp -v /tmp/Caddyfile /etc/caddy/Caddyfile
      - usermod -aG ubuntu caddy
      - systemctl stop caddy
      - systemctl daemon-reload
      - systemctl restart caddy
    ssh_authorized_keys:
      - ${var.SSH_KEY}
    EOT
}

resource "kubernetes_secret" "caddy-cloud-config-secret" {
  metadata {
    name      = "caddy-cc-secret"
    namespace = "default"
    labels = {
      "sensitive" = "false"
    }
  }
  data = {
    "userdata" = local.cloud_init_caddy
  } 
}

resource "harvester_virtualmachine" "caddy-vm" {
  depends_on = [
    kubernetes_secret.caddy-cloud-config-secret
  ]
  name                 = var.CADDY_NAME
  namespace            = "default"
  restart_after_update = true

  description = "Caddy File Server, much more simplier than nginx/httpd/apache2"
  tags = {
    ssh-user = "ubuntu"
  }

  cpu    = var.CADDY_DESIRED_CPU
  memory = var.CADDY_DESIRED_MEM

  efi         = true
  secure_boot = false

  run_strategy = "RerunOnFailure"
  hostname     = var.CADDY_NAME
  machine_type = "q35"

  ssh_keys = [
    harvester_ssh_key.caddy-ssh-key.id
  ]

  network_interface {
    name           = "nic-1"
    wait_for_lease = true
    model = "virtio"
    type = "bridge"
    network_name = harvester_network.mgmt-vlan1-caddy.id
  }

  disk {
    name       = "rootdisk"
    type       = "disk"
    size       = var.CADDY_DISK_SIZE
    bus        = "virtio"
    boot_order = 1

    image       = harvester_image.ubuntu2204-jammy-caddy.id
    auto_delete = true
  }

  cloudinit {
    user_data_secret_name = "caddy-cc-secret"
    network_data = ""
  }
}