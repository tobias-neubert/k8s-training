variable "resource-group-name" {
  default = "k8s-training"
}

variable "azure-location" {
  default = "germanywestcentral"
}

variable "location-fault-domain-count" {
  default = 2
}

variable "username" {
  default = "ubuntu"
}

variable "type-of-cluster" {
  default = "k8s-training"
}

variable "vm_prefix" {
  default = "k8s-training"
}

variable "private_ip_addresses"{
  type = list
}

variable "lb_backend_pool"{
  description = "test"
}

variable "vm_count"{
  default = "1"
}

variable "ssh_key"{
  default = "xyz"
}

variable "image_id"{
  default = "test"
}

variable "subnet_id"{
  default = "test"
}

variable "env" {
  default = "dev"
}

variable "vm_size"{
  default = "Standard_L8s_v2"
}

variable "public_ip_address_id"{
  type = list
}