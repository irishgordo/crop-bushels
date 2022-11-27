variable "SSH_KEY" {
  description = "your public ssh key"
  type = string
}

variable "DR269_VM_PW" {
  description = "vm password for docker rancher v2.6.9 vm"
  type = string
  sensitive = false
  default = "ubuntupw"
}

variable "DR269_DESIRED_CPU" {
  description = "the desired cpu"
  type = number
  default = 2
}

variable "DR269_DESIRED_MEM" {
  description = "the desired mem"
  type = string
  default = "4Gi"
}

variable "DR269_DISK_SIZE" {
  description = "disk size"
  type = string 
  default = "20Gi"
}

variable "DR269_NAME" {
  description = "docker rancher v2.6.9 host name"
  type = string
  default = "docker-rancher-269"
}