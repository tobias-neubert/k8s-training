output "vpc-id" {
  value = "${azurerm_virtual_network.generic-virtual-cloud.id}"
}

output "vpc-cidr" {
  value = "${azurerm_virtual_network.generic-virtual-cloud.address_space}"
}

output "public-subnet-a-id" {
  value = "${azurerm_subnet.public-subnet-a.id}"
}

output "azure-public-nic-ids" {
  value = "${azurerm_network_interface.public-nic.id}"
}