resource "harvester_image" "ubuntu2204-jammy" {
  name      = "ubuntu-2204-jammy"
  namespace = "default"
  storage_class_name = "harvester-longhorn"
  display_name = "jammy-server-cloudimg-amd64-disk-kvm.img"
  source_type  = "download"
  url          = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64-disk-kvm.img"

  lifecycle {
    prevent_destroy = true
  }
}

resource "harvester_image" "ubuntu2004-focal" {
  name = "ubuntu-2004-focal"
  namespace = "default"
  storage_class_name = "harvester-longhorn"
  display_name = "ubuntu-20.04-server-cloudimg-amd64-disk-kvm.img"
  source_type = "download"
  url = "https://cloud-images.ubuntu.com/releases/focal/release/ubuntu-20.04-server-cloudimg-amd64-disk-kvm.img"

  lifecycle {
      prevent_destroy = true
  }
}

resource "harvester_image" "opensuse-leap" {
  name = "opensuse-leap-cloudimg"
  namespace = "default"
  storage_class_name = "harvester-longhorn"
  display_name = "openSUSE-Leap-15.4.x86_64-NoCloud.qcow2"
  source_type = "download"
  url = "https://download.opensuse.org/repositories/Cloud:/Images:/Leap_15.4/images/openSUSE-Leap-15.4.x86_64-NoCloud.qcow2"

  lifecycle {
    prevent_destroy = true
  }
}

resource "harvester_image" "centos-generic-cloud" {
  name = "centos7-generic-cloud"
  namespace = "default"
  storage_class_name = "harvester-longhorn"
  display_name = "CentOS-7-x86_64-GenericCloud.qcow2"
  source_type = "download"
  url = "https://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2"

  lifecycle {
    prevent_destroy = true
  }
}