variable "SSH_KEY" {
  description = "your public ssh key"
  type = string
}

variable "DR26_HEAD_VM_PW" {
  description = "vm password for docker rancher v2.6-head vm"
  type = string
  sensitive = false
  default = "ubuntupw"
}

variable "DR26_HEAD_DESIRED_CPU" {
  description = "the desired cpu"
  type = number
  default = 2
}

variable "DR26_HEAD_DESIRED_MEM" {
  description = "the desired mem"
  type = string
  default = "4Gi"
}

variable "DR26_HEAD_DISK_SIZE" {
  description = "disk size"
  type = string
  default = "20Gi"
}

variable "DR26_HEAD_NAME" {
  description = "docker rancher v2.6-head host name"
  type = string
  default = "docker-rancher-26-head"
}
