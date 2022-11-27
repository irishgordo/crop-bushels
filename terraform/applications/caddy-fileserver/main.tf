module "network" {
  source = "../../modules/network"
}

module "basicimages" {
  source = "../../modules/basicimages"
}

resource "harvester_ssh_key" "caddy-ssh-key" {
  name      = "minio-ssh-key"
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
      :80 {
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
    https://releases.rancher.com/harvester/v1.1.0-rc2/harvester-v1.1.0-rc2-amd64.iso
    -O /home/ubuntu/harvester-isos/harvester-v1-1-0-rc2.iso
  - wget https://releases.rancher.com/harvester/v1.0.3/harvester-v1.0.3-amd64.iso -O /home/ubuntu/harvester-isos/harvester-v103.iso
  - chown -Rv ubuntu:ubuntu /home/ubuntu/harvester-isos
  - systemctl stop caddy
  - cp -v /tmp/Caddyfile /etc/caddy/Caddyfile
  - systemctl restart caddy
ssh_authorized_keys:
  - ssh-ed25519
    AAAAC3NzaC1lZDI1NTE5AAAAIBzZT+yXkr28BJzki4WdisefgyR1hKMXWlJCd9KfajEm
    michael.russell@suse.com
  EOT
}