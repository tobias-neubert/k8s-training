provider "azurerm" {
  features {}
}

module "k8s-training-resource-group" {
  source = "../modules/azure-resource-group"
  resource-group-name = "k8s-training"
  env = "dev"
  type-of-cluster = "k8s-training"
}


