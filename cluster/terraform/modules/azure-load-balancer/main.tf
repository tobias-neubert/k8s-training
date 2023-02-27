provider "azurerm" {
    features {}
}

resource "azurerm_lb" "generic_lb" {
  name                = var.name_of_load_balancer
  location            = var.azure-location
  resource_group_name = var.resource-group-name

  frontend_ip_configuration {
    name                 = var.front_end_config_name
    public_ip_address_id = var.public_ip_id
  }
}

resource "azurerm_lb_backend_address_pool" "lbpool" {
  loadbalancer_id     = azurerm_lb.generic_lb.id
  name                = var.backend_pool_name
}

resource "azurerm_lb_probe" "probe" {
  loadbalancer_id     = azurerm_lb.generic_lb.id
  name                = var.azurerm_lb_probe_name
  port                = var.backend_port
  protocol            = var.protocol
}

resource "azurerm_lb_rule" "generic_lb_rule" {
  loadbalancer_id                = azurerm_lb.generic_lb.id
  name                           = var.name_of_load_balancer_rule
  protocol                       = var.protocol
  frontend_port                  = var.frontend_port
  backend_port                   = var.backend_port
  frontend_ip_configuration_name = var.front_end_config_name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lbpool.id]
}