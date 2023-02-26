provider "azurerm" {
    features {}
}
resource "azurerm_network_security_group" "generic-public-sec-grp" {
  location = var.azure-dc
  name = var.network-secgrp-name
  resource_group_name = var.resource-grp-name
}
resource "azurerm_network_security_rule" "generic-public-rules" {
  name                        = "ssh"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "22"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource-grp-name
  network_security_group_name = azurerm_network_security_group.generic-public-sec-grp.name
}

resource "azurerm_virtual_network" "generic-virtual-cloud" {
  address_space = var.vpc-cidr
  location = var.azure-dc
  name = var.vpc-name
  resource_group_name = var.resource-grp-name
  tags = {
    environment = var.env-type
  }
}

resource "azurerm_subnet" "public-subnet-a" {
  name                 = var.subnet1-name
  resource_group_name  = var.resource-grp-name
  virtual_network_name = azurerm_virtual_network.generic-virtual-cloud.name
  address_prefixes       = [var.subnet1-cidr]
}

resource "azurerm_public_ip" "public-a-ips" {
  name                = "public-ips-a"
  location            = var.azure-dc
  resource_group_name = var.resource-grp-name
  allocation_method   = "Static"

  tags = {
    environment = var.env-type
  }
}

resource "azurerm_network_interface" "public-nic" {
  name                = "public-nic"
  location            = var.azure-dc
  resource_group_name = var.resource-grp-name

  ip_configuration {
    name                          = "public-sub-a"
    subnet_id                     = azurerm_subnet.public-subnet-a.id
    public_ip_address_id = azurerm_public_ip.public-a-ips.id
    private_ip_address_allocation = "Dynamic"
  }
}
