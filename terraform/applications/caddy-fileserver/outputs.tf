output "information_next_steps" {
  value = <<-EOF
    Hello!
    Caddy Fileserver is up and running, hooray!
    You can access the http Caddy fileserver at: http://${harvester_virtualmachine.caddy-vm.network_interface[0].ip_address}:${var.CADDY_FILESERVER_PORT}
    Also!
    The VM's SSH User is: ubuntu
    With the password of: ${var.CADDY_VM_PW}
  EOF
}