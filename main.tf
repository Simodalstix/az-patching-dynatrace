# main.tf

# Configure the Azure Provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0" # Use the latest stable version >= 3.0
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0" # For generating unique names/passwords
    }
    # For fetching Azure AD objects if you want to assign roles to groups/users
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0" # Use the latest stable version >= 2.0
    }
  }
  required_version = ">= 1.0" # Ensure Terraform CLI version is compatible
}

provider "azurerm" {
  features {} # This block is required for the AzureRM provider
  subscription_id = "b86a521f-c7a0-48c6-a0eb-f0d96d10f8ab"
}


locals {
  common_tags = {
    environment = var.environment
    project     = var.project_prefix
  }
}

# --- Resource Group ---
resource "azurerm_resource_group" "rg_patch_lab" {
  name     = var.resource_group_name
  location = var.location

  tags = {

    project = "AzurePatchLab"
    owner   = "PlatformEngineer"
  }
}

# --- Virtual Network ---
resource "azurerm_virtual_network" "vnet_lab" {
  name                = "vnet-${var.project_prefix}-lab"
  address_space       = [var.vnet_address_space]
  location            = azurerm_resource_group.rg_patch_lab.location
  resource_group_name = azurerm_resource_group.rg_patch_lab.name

  tags = azurerm_resource_group.rg_patch_lab.tags
}

# --- Subnets ---
resource "azurerm_subnet" "subnet_web" {
  name                 = "subnet-${var.project_prefix}-web"
  resource_group_name  = azurerm_resource_group.rg_patch_lab.name
  virtual_network_name = azurerm_virtual_network.vnet_lab.name
  address_prefixes     = [var.subnet_web_address_prefix]
}

resource "azurerm_subnet" "subnet_app" {
  name                 = "subnet-${var.project_prefix}-app"
  resource_group_name  = azurerm_resource_group.rg_patch_lab.name
  virtual_network_name = azurerm_virtual_network.vnet_lab.name
  address_prefixes     = [var.subnet_app_address_prefix]
}

# --- Network Security Group for Web Subnet (Public-facing, so allows HTTP/S, limited SSH) ---
resource "azurerm_network_security_group" "nsg_web" {
  name                = "nsg-${var.project_prefix}-web"
  location            = azurerm_resource_group.rg_patch_lab.location
  resource_group_name = azurerm_resource_group.rg_patch_lab.name

  # Allow HTTP/S from Internet (for the Load Balancer frontend)
  security_rule {
    name                       = "AllowHTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  # Allow SSH from specific management IP (for direct VM access if needed, though LB is primary)
  security_rule {
    name                       = "AllowSSH"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.allowed_source_ip_for_ssh
    destination_address_prefix = "*"
  }

  # Allow Load Balancer Health Probes (from Azure Load Balancer service tag)
  security_rule {
    name                       = "AllowLBHealthProbe"
    priority                   = 210
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80" # Or the port your health probe will use
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  tags = azurerm_resource_group.rg_patch_lab.tags
}

resource "azurerm_subnet_network_security_group_association" "nsg_web_association" {
  subnet_id                 = azurerm_subnet.subnet_web.id
  network_security_group_id = azurerm_network_security_group.nsg_web.id
}

# --- Network Security Group for App Subnet (Internal, limited RDP/SSH) ---
resource "azurerm_network_security_group" "nsg_app" {
  name                = "nsg-${var.project_prefix}-app"
  location            = azurerm_resource_group.rg_patch_lab.location
  resource_group_name = azurerm_resource_group.rg_patch_lab.name

  security_rule {
    name                       = "AllowRDP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = var.allowed_source_ip_for_rdp # Restrict RDP
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowSSH"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.allowed_source_ip_for_ssh
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowWebToApp"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"                                        # Example app port
    source_address_prefix      = azurerm_subnet.subnet_web.address_prefixes[0] # Only from web subnet
    destination_address_prefix = "*"
  }

  tags = azurerm_resource_group.rg_patch_lab.tags
}

resource "azurerm_subnet_network_security_group_association" "nsg_app_association" {
  subnet_id                 = azurerm_subnet.subnet_app.id
  network_security_group_id = azurerm_network_security_group.nsg_app.id
}

# --- Availability Set for RHEL VMs ---
resource "azurerm_availability_set" "avset_rhel" {
  name                         = "avset-${var.project_prefix}-rhel"
  location                     = azurerm_resource_group.rg_patch_lab.location
  resource_group_name          = azurerm_resource_group.rg_patch_lab.name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 5

  tags = azurerm_resource_group.rg_patch_lab.tags
}

# --- Azure Standard Load Balancer for RHEL Web Tier ---
resource "azurerm_public_ip" "pip_lb" {
  name                = "pip-${var.project_prefix}-lb"
  location            = azurerm_resource_group.rg_patch_lab.location
  resource_group_name = azurerm_resource_group.rg_patch_lab.name
  allocation_method   = "Static"
  sku                 = "Standard" # Required for Standard Load Balancer

  tags = azurerm_resource_group.rg_patch_lab.tags
}

resource "azurerm_lb" "lb_web" {
  name                = "lb-${var.project_prefix}-web"
  location            = azurerm_resource_group.rg_patch_lab.location
  resource_group_name = azurerm_resource_group.rg_patch_lab.name
  sku                 = "Standard" # Standard SKU for production-grade features and Availability Zones

  frontend_ip_configuration {
    name                 = "frontend-public-ip"
    public_ip_address_id = azurerm_public_ip.pip_lb.id
  }

  tags = azurerm_resource_group.rg_patch_lab.tags
}

resource "azurerm_lb_backend_address_pool" "lb_backend_pool_rhel" {
  loadbalancer_id = azurerm_lb.lb_web.id
  name            = "backend-pool-rhel-web"
}

resource "azurerm_lb_probe" "lb_probe_http" {
  loadbalancer_id     = azurerm_lb.lb_web.id
  name                = "http-probe-80"
  protocol            = "Tcp" # Or Http if a web server running
  port                = 80
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_lb_rule" "lb_rule_http" {
  loadbalancer_id                = azurerm_lb.lb_web.id
  name                           = "http-rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "frontend-public-ip"
  probe_id                       = azurerm_lb_probe.lb_probe_http.id

  # backend address pool
  backend_address_pool_ids = [azurerm_lb_backend_address_pool.lb_backend_pool_rhel.id]
}

# --- RHEL VMs (Using count for multiple instances) ---
resource "random_string" "rhel_password_suffix" {
  length  = 8
  special = false
  upper   = false
  numeric = true
}

resource "azurerm_availability_set" "avset_windows" {
  name                         = "as-win-${var.project_prefix}"
  location                     = var.location
  resource_group_name          = azurerm_resource_group.rg_patch_lab.name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 5
  managed                      = true
  tags                         = local.common_tags
}

# Network Interfaces for RHEL VMs - NO PUBLIC IPs directly assigned to VMs
resource "azurerm_network_interface" "nic_rhel" {
  count               = var.rhel_vm_count
  name                = "nic-${var.project_prefix}-rhel-${format("%02d", count.index + 1)}"
  location            = azurerm_resource_group.rg_patch_lab.location
  resource_group_name = azurerm_resource_group.rg_patch_lab.name

  ip_configuration {
    name                          = "ipconfig-${var.project_prefix}-rhel-${format("%02d", count.index + 1)}"
    subnet_id                     = azurerm_subnet.subnet_web.id
    private_ip_address_allocation = "Dynamic"
    # NO public_ip_address_id here, traffic comes via LB
  }

  tags = azurerm_resource_group.rg_patch_lab.tags
}

# Associate RHEL NICs with the Load Balancer Backend Pool
resource "azurerm_network_interface_backend_address_pool_association" "nic_rhel_lb_association" {
  count                   = var.rhel_vm_count
  network_interface_id    = azurerm_network_interface.nic_rhel[count.index].id
  ip_configuration_name   = azurerm_network_interface.nic_rhel[count.index].ip_configuration[0].name
  backend_address_pool_id = azurerm_lb_backend_address_pool.lb_backend_pool_rhel.id
}


# --- Windows Server VM ---
resource "random_password" "windows_admin_password" {
  length           = 20
  special          = true
  override_special = "!@#$%^&*"
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
}

resource "azurerm_public_ip" "pip_windows" {
  name                = "pip-${var.project_prefix}-win01"
  location            = azurerm_resource_group.rg_patch_lab.location
  resource_group_name = azurerm_resource_group.rg_patch_lab.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = azurerm_resource_group.rg_patch_lab.tags
}

resource "azurerm_network_interface" "nic_windows" {
  name                = "nic-${var.project_prefix}-win01"
  location            = azurerm_resource_group.rg_patch_lab.location
  resource_group_name = azurerm_resource_group.rg_patch_lab.name

  ip_configuration {
    name                          = "ipconfig-${var.project_prefix}-win01"
    subnet_id                     = azurerm_subnet.subnet_app.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip_windows.id # Keep public IP for direct RDP
  }

  tags = azurerm_resource_group.rg_patch_lab.tags
}

resource "azurerm_resource_group_policy_assignment" "vm_update_assessment_policy" {
  name                 = "Enable-VM-Update-Assessment-For-${var.project_prefix}"
  resource_group_id    = azurerm_resource_group.rg_patch_lab.id # CORRECTED: Assign to this specific resource group
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/59efceea-0c96-497e-a4a1-4eb2290dac15"
  display_name         = "Configure machines to receive Azure automatic VM guest OS patches by platform for ${var.project_prefix} Lab"
  description          = "Assigns a policy to enable automatic VM guest OS patching assessment for this lab environment."

  location = azurerm_resource_group.rg_patch_lab.location # Or a specific region string like "australiaeast"
  identity {
    type = "SystemAssigned"
  }


}
resource "azurerm_role_assignment" "policy_assignment_contributor_role" {
  scope                = azurerm_resource_group.rg_patch_lab.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_resource_group_policy_assignment.vm_update_assessment_policy.identity[0].principal_id
}

module "monitoring" {
  source              = "./modules/monitoring"
  vm_ids              = module.rhel_vms.vm_ids
  project_prefix      = var.project_prefix
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_patch_lab.name
  tags                = local.common_tags
}

module "windows_vm" {
  source                    = "./modules/windows-vm"
  name_prefix               = "win-vm-${var.project_prefix}"
  location                  = var.location
  resource_group_name       = azurerm_resource_group.rg_patch_lab.name
  size                      = "Standard_B2ms"
  admin_username            = var.windows_admin_username
  admin_password            = random_password.windows_admin_password.result
  nic_id                    = azurerm_network_interface.nic_windows.id
  avset_id                  = azurerm_availability_set.avset_windows.id
  public_ip                 = azurerm_public_ip.pip_windows.ip_address
  dynatrace_environment_url = var.dynatrace_environment_url
  dynatrace_api_token       = var.dynatrace_api_token
  tags                      = local.common_tags
}

module "rhel_vms" {
  source                    = "./modules/linux-vm"
  vm_count                  = var.rhel_vm_count
  name_prefix               = "rhel-vm-${var.project_prefix}"
  location                  = var.location
  resource_group_name       = azurerm_resource_group.rg_patch_lab.name
  size                      = "Standard_B2s"
  admin_username            = var.linux_admin_username
  admin_password            = "${var.linux_admin_password_prefix}${random_string.rhel_password_suffix.result}"
  avset_id                  = azurerm_availability_set.avset_rhel.id
  nic_ids                   = azurerm_network_interface.nic_rhel[*].id
  disk_size                 = 128
  dynatrace_environment_url = var.dynatrace_environment_url
  dynatrace_api_token       = var.dynatrace_api_token
  tags                      = local.common_tags
}
