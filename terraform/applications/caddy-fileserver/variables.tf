variable "SSH_KEY" {
    description = "ssh key for your access to the vm"
    type = string
}

variable "CADDY_DESIRED_CPU" {
    description = "caddy vm file server desired cpu"
    type = number
    default = 2
}

variable "CADDY_DESIRED_MEM" {
    description = "caddy vm desired mem quantity"
    type = string
    default = "4Gi"
}

variable "CADDY_DISK_SIZE" {
    description = "caddy vm file server default storage size"
    type = string
    default = "50Gi"
}

variable "CADDY_NAME" {
    description = "caddy vm hostname"
    type = string
    default = "caddy-fileserver"
}

variable "CADDY_VM_PW" {
    description = "ubuntu user password"
    type = string
    default = "ubuntupw"
}

variable "CADDY_FILESERVER_PORT" {
    description = "fileserver port caddy serves on"
    type = number
    default = 80
}
