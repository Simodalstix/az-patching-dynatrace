# main-modular.tf - Refactored modular version

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.0"
}

provider "azurerm" {
  features {}
  subscription_id = "b86a521f-c7a0-48c6-a0eb-f0d96d10f8ab"
}

locals {
  common_tags = {
    environment = var.environment
    project     = var.project_prefix
  }
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.common_tags
}

# Availability Sets
resource "azurerm_availability_set" "linux" {
  name                         = "avset-${var.project_prefix}-linux"
  location                     = var.location
  resource_group_name          = azurerm_resource_group.main.name
  platform_fault_domain_count = 2
  platform_update_domain_count = 5
  managed                      = true
  tags                         = local.common_tags
}

resource "azurerm_availability_set" "windows" {
  name                         = "avset-${var.project_prefix}-windows"
  location                     = var.location
  resource_group_name          = azurerm_resource_group.main.name
  platform_fault_domain_count = 2
  platform_update_domain_count = 5
  managed                      = true
  tags                         = local.common_tags
}

# Network Module
module "network" {
  source                        = "./modules/network"
  project_prefix                = var.project_prefix
  location                      = var.location
  resource_group_name           = azurerm_resource_group.main.name
  vnet_address_space            = var.vnet_address_space
  subnet_web_address_prefix     = var.subnet_web_address_prefix
  subnet_app_address_prefix     = var.subnet_app_address_prefix
  allowed_source_ip_for_ssh     = var.allowed_source_ip_for_ssh
  allowed_source_ip_for_rdp     = var.allowed_source_ip_for_rdp
  tags                          = local.common_tags
}

# Network Interfaces
resource "azurerm_network_interface" "linux" {
  count               = var.rhel_vm_count
  name                = "nic-${var.project_prefix}-linux-${format("%02d", count.index + 1)}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = module.network.web_subnet_id
    private_ip_address_allocation = "Dynamic"
  }

  tags = local.common_tags
}

resource "azurerm_network_interface_backend_address_pool_association" "linux" {
  count                   = var.rhel_vm_count
  network_interface_id    = azurerm_network_interface.linux[count.index].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = module.network.lb_backend_pool_id
}

resource "azurerm_public_ip" "windows" {
  name                = "pip-${var.project_prefix}-windows"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.common_tags
}

resource "azurerm_network_interface" "windows" {
  name                = "nic-${var.project_prefix}-windows"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = module.network.app_subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.windows.id
  }

  tags = local.common_tags
}

# Password Generation
resource "random_password" "linux" {
  length  = 16
  special = true
}

resource "random_password" "windows" {
  length  = 20
  special = true
}

# VM Modules
module "linux_vms" {
  source                    = "./modules/linux-vm"
  vm_count                  = var.rhel_vm_count
  name_prefix               = "linux-${var.project_prefix}"
  location                  = var.location
  resource_group_name       = azurerm_resource_group.main.name
  size                      = "Standard_B2s"
  admin_username            = var.linux_admin_username
  admin_password            = random_password.linux.result
  avset_id                  = azurerm_availability_set.linux.id
  nic_ids                   = azurerm_network_interface.linux[*].id
  disk_size                 = 128
  dynatrace_environment_url = var.dynatrace_environment_url
  dynatrace_api_token       = var.dynatrace_api_token
  tags                      = local.common_tags
}

module "windows_vm" {
  source                    = "./modules/windows-vm"
  name_prefix               = "win-${var.project_prefix}"
  location                  = var.location
  resource_group_name       = azurerm_resource_group.main.name
  size                      = "Standard_B2ms"
  admin_username            = var.windows_admin_username
  admin_password            = random_password.windows.result
  nic_id                    = azurerm_network_interface.windows.id
  avset_id                  = azurerm_availability_set.windows.id
  public_ip                 = azurerm_public_ip.windows.ip_address
  dynatrace_environment_url = var.dynatrace_environment_url
  dynatrace_api_token       = var.dynatrace_api_token
  tags                      = local.common_tags
}

# Monitoring Module
module "monitoring" {
  source              = "./modules/monitoring"
  vm_ids              = concat(module.linux_vms.vm_ids, [module.windows_vm.vm_id])
  project_prefix      = var.project_prefix
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  alert_email         = var.alert_email
  tags                = local.common_tags
}

# Patch Management Module
module "patch_management" {
  source              = "./modules/patch-management"
  project_prefix      = var.project_prefix
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  linux_vm_ids        = module.linux_vms.vm_ids
  windows_vm_ids      = [module.windows_vm.vm_id]
  tags                = local.common_tags
}

# Sample Application Module
module "sample_app" {
  source                       = "./modules/sample-app"
  project_prefix               = var.project_prefix
  location                     = var.location
  resource_group_name          = azurerm_resource_group.main.name
  linux_vm_ids                 = module.linux_vms.vm_ids
  log_analytics_workspace_id   = module.monitoring.log_analytics_workspace_id
  tags                         = local.common_tags
}

# Security Module
module "security" {
  source            = "./modules/security"
  project_prefix    = var.project_prefix
  location          = var.location
  resource_group_id = azurerm_resource_group.main.id
}