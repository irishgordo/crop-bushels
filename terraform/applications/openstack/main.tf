
resource "harvester_image" "ubuntu2004-focal-openstack" {
  name = "focal-openstack"
  namespace = "default"
  storage_class_name = "harvester-longhorn"
  display_name = "ubuntu-20.04-server-cloudimg-amd64-disk-kvm-ostack.img"
  source_type = "download"
  url = "https://cloud-images.ubuntu.com/releases/focal/release/ubuntu-20.04-server-cloudimg-amd64-disk-kvm.img"
}

resource "harvester_network" "mgmt-vlan1-ostack" {
  name      = "mgmt-vlan1-ostack"
  namespace = "default"

  vlan_id = 1

  route_mode           = "auto"
  route_dhcp_server_ip = ""

  cluster_network_name = "mgmt"
}

resource "harvester_ssh_key" "openstack-ssh-key" {
  name      = "openstack-ssh-key"
  namespace = "default"

  public_key = var.SSH_KEY
}

locals {
  cloud_init_openstack = <<-EOT
    #cloud-config
    password: ubuntupw
    chpasswd:
    expire: false
    ssh_pwauth: true
    package_update: true
    packages:
    - qemu-guest-agent
    - git
    - libvirt-daemon
    - python3-pip
    - linux-modules-extra-5.8.0-48-generic
    - neovim
    - apt-transport-https
    - wget
    - ca-certificates
    - curl
    - gnupg-agent
    - gnupg
    - lsb-release
    - software-properties-common
    - coreutils
    write_files:
    - path: /tmp/local.conf
      content: |
        [[local|localrc]]
        ADMIN_PASSWORD=${var.OPENSTACK_ADMIN_PW}
        DATABASE_PASSWORD=${var.OPENSTACK_DB_PW}
        RABBIT_PASSWORD=${var.OPENSTACK_RABBIT_PW}
        SERVICE_PASSWORD=${var.OPENSTACK_SERVICE_PW}
      owner: ubuntu:ubuntu
    runcmd:
    - - systemctl
        - enable
        - --now
        - qemu-guest-agent.service
    - cd /home/ubuntu && git clone https://opendev.org/openstack/devstack
    - mkdir -p /opt/stack/logs/
    - chown -Rv ubuntu:ubuntu /opt/stack
    - cd /home/ubuntu/devstack && git checkout stable/yoga
    - cp -v /tmp/local.conf /home/ubuntu/devstack/local.conf
    - chmod +x /home/ubuntu/devstack/stack.sh
    - chown -Rv ubuntu:ubuntu /home/ubuntu/devstack
    - su -c '/home/ubuntu/devstack/stack.sh' - ubuntu
    - pvcreate /dev/sda
    - vgextend stack-volumes-lvmdriver-1 /dev/sda
    - systemctl daemon-reload
    - systemctl restart lvm2-lvmetad.service
    - systemctl restart devstack@c-vol
    ssh_authorized_keys:
    - ${var.SSH_KEY}
    EOT
}

resource "kubernetes_secret" "openstack-cloud-config-secret" {
  metadata {
    name      = "openstack-cc-secret"
    namespace = "default"
    labels = {
      "sensitive" = "false"
    }
  }
  data = {
    "userdata" = local.cloud_init_openstack
  } 
}

resource "harvester_virtualmachine" "openstack-vm" {
  depends_on = [
    kubernetes_secret.openstack-cloud-config-secret
  ]
  name                 = var.OPENSTACK_NAME
  namespace            = "default"
  restart_after_update = true

  description = "Openstack stable/zed DEVSTACK BASED instance"
  tags = {
    ssh-user = "ubuntu"
  }

  cpu    = var.OPENSTACK_DESIRED_CPU
  memory = var.OPENSTACK_DESIRED_MEM

  efi         = true
  secure_boot = false

  run_strategy = "RerunOnFailure"
  hostname     = var.OPENSTACK_NAME
  machine_type = "q35"

  ssh_keys = [
    harvester_ssh_key.openstack-ssh-key.id
  ]

  network_interface {
    name           = "nic-1"
    wait_for_lease = true
    model = "virtio"
    type = "bridge"
    network_name = harvester_network.mgmt-vlan1-ostack.id
  }

  disk {
    name       = "rootdisk"
    type       = "disk"
    size       = var.OPENSTACK_OS_DISK_SIZE
    bus        = "virtio"
    boot_order = 1

    image       = harvester_image.ubuntu2004-focal-openstack.id
    auto_delete = true
  }

  disk {
    name       = "datadisk"
    type       = "disk"
    size       = var.OPENSTACK_DATA_DISK_SIZE
    bus        = "sata"
    boot_order = 2

    auto_delete = true
  }

  cloudinit {
    user_data_secret_name = "openstack-cc-secret"
    network_data = ""
  }
}