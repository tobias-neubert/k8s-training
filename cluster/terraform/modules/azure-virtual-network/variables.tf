variable "vnet-cidr" {
  default = ["10.240.0.0/24"]
  type = list
}

variable "resource-group-name" {
  default = "k8s-training"
}

variable "azure-location" {
  default = "germanywestcentral"
}

variable "vnet-name" {
  default = "k8s-training"
}

variable "env" {
  default = "stg"
}

variable "type-of-cluster" {
  default = "k8s-training"
}

variable "vnet-subnet-name" {
  default = "k8s-training"
}

variable "vnet-sec-group-name" {
  default = "k8s-training"
}

variable "subnet_id" {
  default = "k8s-training"
}