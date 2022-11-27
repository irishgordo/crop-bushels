variable "OPENSTACK_ADMIN_PW" {
  description = "openstack admin pw"
  type = string
  default = "pwpassword"
}

variable "OPENSTACK_DB_PW" {
    description = "openstack db pw"
    type = string
    default = "dbpwpassword"
}

variable "OPENSTACK_RABBIT_PW" {
  description = "rabbit openstack pw"
  type = string
  default = "rbpwpassword"
}

variable "OPENSTACK_SERVICE_PW" {
    description = "service openstack pw"
    type = string
    default = "servpwpassword"
}

variable "OPENSTACK_DESIRED_CPU" {
  description = "base cpu"
  type = number
  default = 4
}

variable "OPENSTACK_DESIRED_MEM" {
  description = "mem"
  type = string 
  default = "12Gi"
}

variable "OPENSTACK_OS_DISK_SIZE" {
  description = "os disk"
  type = string 
  default = "50Gi"
}

variable "OPENSTACK_DATA_DISK_SIZE" {
  description = "data disk"
  type = string 
  default = "100Gi"
}

variable "OPENSTACK_NAME" {
  description = "openstack name"
  type = string
  default = "openstack-devstack-zed"
}

variable "SSH_KEY" {
  description = "ssh key"
  type = string
}