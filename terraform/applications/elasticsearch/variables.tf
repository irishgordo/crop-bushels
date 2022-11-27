variable "SSH_KEY" {
  description = "your public ssh key"
  type = string
}

variable "ES_VM_PW" {
  description = "vm password for ES"
  type = string
  sensitive = false
  default = "ubuntupw"
}

variable "ES_DESIRED_CPU" {
  description = "the desired cpu"
  type = number
  default = 4
}

variable "ES_DESIRED_MEM" {
  description = "the desired mem"
  type = string
  default = "10Gi"
}

variable "ES_DISK_SIZE" {
  description = "disk size"
  type = string 
  default = "40Gi"
}

variable "ES_NAME" {
  description = "ES host name"
  type = string
  default = "elasticsearch-68-box"
}