resource "harvester_network" "mgmt-vlan1" {
  name      = "mgmt-vlan1"
  namespace = "default"

  vlan_id = 1

  route_mode           = "auto"
  route_dhcp_server_ip = ""

  cluster_network_name = "mgmt"

}
