#*********************************
variable "network-secgrp-name" {
  default = "test"
}
variable "resource-grp-name" {
  default = "test"
}
variable "azure-dc" {
  default = "germanywestcentral"
}

#*********************************

variable "vpc-cidr" {
  type = list
  default = ["10.0.0.0/16"]
}
variable "vpc-name" {
  default = "test"
}
variable "subnet1-name" {
  default = "linkedin-private-a"
}
variable "subnet1-cidr" {
  default = "10.0.1.0/24"
}
variable "env-type" {
  default = "Devlopment"
}
