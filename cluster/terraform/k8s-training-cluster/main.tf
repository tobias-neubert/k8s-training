module "k8s-training-virtual-network" {
  source = "../modules/azure-virtual-network"
  vnet-cidr = ["10.240.0.0/24"]
  vnet-name = "k8s-training-vnet"
  vnet-subnet-name = "k8s-training-subnet"
  vnet-sec-group-name = "k8s-training-security_group"
  env = "dev"
  azure-location = "germanywestcentral"
  resource-group-name = "k8s-training"
  type-of-cluster = "k8s-training"
}

module "k8s-training-api-server-public-ip" {
  source = "../modules/azure-public-ip"
  name_of_ip = "k8s_master_load_balancer"
  resource-group-name = "k8s-training"
  azure-location = "germanywestcentral"
  env = "dev"
  type-of-cluster = "k8s-training"
}

module "Worker0" {
  source = "../modules/azure-public-ip"
  name_of_ip = "Worker0"
  resource-group-name = "k8s-training"
  azure-location = "germanywestcentral"
  env = "dev"
  type-of-cluster = "k8s-training"
}

module "Controller0" {
  source = "../modules/azure-public-ip"
  name_of_ip = "Controller0"
  resource-group-name = "k8s-training"
  azure-location = "germanywestcentral"
  env = "dev"
  type-of-cluster = "k8s-training"
}

module "k8s-api-public-loadbalancer-master" {
  source = "../modules/azure-load-balancer"
  name_of_load_balancer = "k8s_training_master_lb"
  azure-location = "germanywestcentral"
  resource-group-name = "k8s-training"
  front_end_config_name = "k8s-frontend-config"
  public_ip_id = "${module.k8s-training-api-server-public-ip.id}"
  backend_pool_name = "k8s-control-plane"
  frontend_port = "6443"
  backend_port =  "6443"
  protocol = "Tcp"
  name_of_load_balancer_rule = "controller-lb-rule"
  azurerm_lb_probe_name = "k8s_master_probe"
}

module "master" {
  source = "../modules/azure-vms-master"
  azure-location = "germanywestcentral"
  resource-group-name = "k8s-training"
  private_ip_addresses = ["10.240.0.10"]
  vm_prefix = "controller"
  public_ip_address_id = ["${module.Controller0.id}"]
  vm_size = "Standard_L8s_v2"
  env = "dev"
  type-of-cluster = "k8s-training"
  vm_count = 1
  subnet_id = "${module.k8s-training-virtual-network.subnet_id}"
  image_id = "subscriptions/cc700aee-fc50-4019-846a-4226bd0cde59/resourceGroups/k8s-training/providers/Microsoft.Compute/images/k8s_controller"
  ssh_key = "${file("~/.ssh/id_rsa-k8s-training.pub")}"
  lb_backend_pool = "${module.k8s-api-public-loadbalancer-master.lb_backend_pool}"
}

