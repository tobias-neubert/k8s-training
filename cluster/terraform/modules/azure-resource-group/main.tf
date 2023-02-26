resource "azurerm_resource_group" "generic-resource-gp" {
  name     = var.resource-group-name
  location = var.azure-data-center

  tags = {
    environment = var.env
    cluster = var.type-of-cluster
  }
}
