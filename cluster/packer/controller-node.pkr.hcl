variable "arm_client_id" {
  default = env("ARM_CLIENT_ID")
}
variable "arm_client_secret" {
  default = env("ARM_CLIENT_SECRET")
}
variable "arm_subscription_id" {
  default = env("ARM_SUBSCRIPTION_ID")
}
variable "arm_tenant_id" {
  default = env("ARM_TENANT_ID")
}

source "azure-arm" "k8s-controller" {
  azure_tags = {
    env             = "dev"
    type-of-cluster = "k8s-training"
  }
  client_id                         = var.arm_client_id
  client_secret                     = var.arm_client_secret
  image_offer                       = "0001-com-ubuntu-confidential-vm-jammy"
  image_publisher                   = "Canonical"
  image_sku                         = "22_04-lts-cvm"
  location                          = "germanywestcentral"
  managed_image_name                = "k8s_controller"
  managed_image_resource_group_name = "k8s-training"
  os_type                           = "Linux"
  subscription_id                   = var.arm_subscription_id
  tenant_id                         = var.arm_tenant_id
  vm_size                           = "Standard_L8s_v2"
}

build {
  sources = ["source.azure-arm.k8s-controller"]

  provisioner "shell" {
    script = "controller.sh"
  }

}
