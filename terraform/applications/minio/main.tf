module "network" {
    source = "../../modules/network"
}

resource "harvester_image" "ubuntu2204-jammy" {
  name      = "ubuntu-2204-jammy"
  namespace = "default"
  storage_class_name = "harvester-longhorn"
  display_name = "jammy-server-cloudimg-amd64-disk-kvm.img"
  source_type  = "download"
  url          = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64-disk-kvm.img"
}

resource "harvester_ssh_key" "minio-ssh-key" {
  name      = "minio-ssh-key"
  namespace = "default"

  public_key = var.SSH_KEY
}

# --certs-dir /home/minio-user/.minio/certs" ...tls has issues? idk really what's happening with minio and certgen
# it looks good, but ideally serving an "S3" over https would be better than not for integration infrastructure
# also possibly adding something like:
# - mkdir -p /home/minio-user/.minio/certs
# - wget https://github.com/minio/certgen/releases/download/v1.2.1/certgen-linux-amd64 -P /home/minio-user/
# - chmod +x /home/minio-user/certgen-linux-amd64
# - cp -v /home/minio-user/certgen-linux-amd64 /usr/local/bin/certgen
# - cd /home/minio-user/.minio/certs && /usr/local/bin/certgen -host "localhost"
locals {
  cloud_init_config_base = <<-EOF
      #cloud-config
      password: ${var.MINIO_VM_PW}
      chpasswd:
        expire: false
      ssh_pwauth: true
      package_update: true
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
        - tmux
      write_files:
        - path: /tmp/minio
          owner: ubuntu:ubuntu
          content: |
            MINIO_VOLUMES="${var.MINIO_VOLUMES}"
            MINIO_OPTS="--console-address ${var.MINIO_CONSOLE_ADDRESS} --address ${var.MINIO_ADDRESS}"
            MINIO_ROOT_USER="${var.MINIO_ROOT_USER}"
            MINIO_ROOT_PASSWORD="${var.MINIO_ROOT_PASSWORD}" 
        - path: /tmp/minio.service
          owner: ubuntu:ubuntu
          content: |
            [Unit]
            Description=MinIO
            Documentation=https://docs.min.io
            Wants=network-online.target
            After=network-online.target
            AssertFileIsExecutable=/usr/local/bin/minio

            [Service]
            WorkingDirectory=/usr/local/

            User=minio-user
            Group=minio-user
            ProtectProc=invisible

            EnvironmentFile=/etc/default/minio
            ExecStartPre=/bin/bash -c "if [ -z \"\${var.MINIO_VOLUMES}\" ]; then echo \"Variable MINIO_VOLUMES not set in /etc/default/minio\"; exit 1; fi"
            ExecStart=/usr/local/bin/minio server $MINIO_OPTS $MINIO_VOLUMES

            # Let systemd restart this service always
            Restart=always

            # Specifies the maximum file descriptor number that can be opened by this process
            LimitNOFILE=65536

            # Specifies the maximum number of threads this process can create
            TasksMax=infinity

            # Disable timeout logic and wait until process is stopped
            TimeoutStopSec=infinity
            SendSIGKILL=no

            [Install]
            WantedBy=multi-user.target
      runcmd:
        - - systemctl
          - enable
          - --now
          - qemu-guest-agent.service
        - wget
          ${var.MINIO_VERSION_DEB_PKG}
          -O minio.deb
        - dpkg -i minio.deb
        - mkdir -p ${var.MINIO_VOLUMES}
        - mkdir -p /var/log/minio
        - groupadd -r minio-user
        - useradd -M -r -g minio-user minio-user
        - chown -Rv minio-user:minio-user /home/minio-user
        - chown -Rv minio-user:minio-user ${var.MINIO_VOLUMES}
        - chmod -R minio-user=rwx ${var.MINIO_VOLUMES}
        - mkdir -p /etc/default
        - cp -v /tmp/minio /etc/default/minio
        - chown -v minio-user:minio-user /etc/default/minio
        - cp -v /tmp/minio.service /etc/systemd/system
        - systemctl daemon-reload
        - systemctl daemon-reload
        - systemctl enable minio
        - systemctl start minio
      ssh_authorized_keys:
        - ${var.SSH_KEY}
EOF
}

resource "kubernetes_secret" "minio-cloud-config-secret" {
  metadata {
    name      = "minio-cc-secret"
    namespace = "default"
    labels = {
      "sensitive" = "false"
    }
  }
  data = {
    "userdata" = local.cloud_init_config_base
  } 
}

resource "harvester_virtualmachine" "minio-vm" {
  depends_on = [
    kubernetes_secret.minio-cloud-config-secret
  ]
  name                 = var.MINIO_NAME
  namespace            = "default"
  restart_after_update = true

  description = "MinIO S3 Backup Server"
  tags = {
    ssh-user = "ubuntu"
  }

  cpu    = var.MINIO_DESIRED_CPU
  memory = var.MINIO_DESIRED_MEM

  efi         = true
  secure_boot = false

  run_strategy = "RerunOnFailure"
  hostname     = var.MINIO_NAME
  machine_type = "q35"

  ssh_keys = [
    harvester_ssh_key.minio-ssh-key.id
  ]

  network_interface {
    name           = "nic-1"
    wait_for_lease = true
    model = "virtio"
    type = "bridge"
    network_name = module.network.basic_vlan1_vm_network
  }

  disk {
    name       = "rootdisk"
    type       = "disk"
    size       = var.MINIO_DISK_SIZE
    bus        = "virtio"
    boot_order = 1

    image       = harvester_image.ubuntu2204-jammy.id
    auto_delete = true
  }

# https://deploy.equinix.com/developers/guides/minio/
  cloudinit {
    user_data_secret_name = "minio-cc-secret"
    network_data = ""
  }
}