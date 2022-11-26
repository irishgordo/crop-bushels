output "information_next_steps" {
  value = <<-EOF
    Hello!
    MinIO is FINISHED Provisioning, hooray!
    You can access the WebUI Console At: ${harvester_virtualmachine.minio-vm.network_interface[0].ip_address}${var.MINIO_CONSOLE_ADDRESS}
    With the credentials of User: ${var.MINIO_ROOT_USER}
    And the User's Password of: ${var.MINIO_ROOT_PASSWORD}
    Also!
    The VM's SSH User is: ubuntu
    With the password of: ${var.MINIO_VM_PW}
  EOF
# TODO: impl, coalesce logic for 'truthy' ness of null/empty string
#   precondition {
#     condition     = harvester_virtualmachine.minio-vm.network_interface[0].ip_address
#     error_message = "The IP Address of the MinIO VM is not available yet"
#   }
}