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

# Add AzureAD provider for RBAC (only if you intend to fetch AAD groups/users)
# provider "azuread" {}

# --- Resource Group ---
resource "azurerm_resource_group" "rg_patch_lab" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    environment = var.environment_tag
    project     = "AzurePatchLab"
    owner       = "PlatformEngineer"
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

resource "azurerm_linux_virtual_machine" "rhel_vm" {
  count                           = var.rhel_vm_count
  name                            = "rhel-vm-${var.project_prefix}-${format("%02d", count.index + 1)}"
  resource_group_name             = azurerm_resource_group.rg_patch_lab.name
  location                        = azurerm_resource_group.rg_patch_lab.location
  size                            = "Standard_B2s" # Cost-effective size for lab
  admin_username                  = var.linux_admin_username
  admin_password                  = "${var.linux_admin_password_prefix}${random_string.rhel_password_suffix.result}"
  disable_password_authentication = false # Enable password for easier lab access

  # Attach to Network Interface which will be associated with LB Backend Pool
  network_interface_ids = [
    azurerm_network_interface.nic_rhel[count.index].id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 64
  }

  source_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "9-LVM"
    version   = "latest"
  }

  # Join to Availability Set
  availability_set_id = azurerm_availability_set.avset_rhel.id

  # Dynatrace OneAgent Deployment (Conceptual via Custom Data)
  custom_data = base64encode(templatefile("${path.module}/scripts/install_dynatrace_rhel.sh", {
    dynatrace_environment_url = var.dynatrace_environment_url
    dynatrace_api_token       = var.dynatrace_api_token
    vm_name                   = "rhel-vm-${var.project_prefix}-${format("%02d", count.index + 1)}"
  }))

  tags = merge(azurerm_resource_group.rg_patch_lab.tags, {
    os_type  = "Linux"
    app_tier = "Web"
  })
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

resource "azurerm_windows_virtual_machine" "windows_vm" {
  name                     = "win-vm-${var.project_prefix}-app01" # This is the Azure resource name
  resource_group_name      = azurerm_resource_group.rg_patch_lab.name
  location                 = azurerm_resource_group.rg_patch_lab.location
  size                     = "Standard_B2ms" # More memory for app server
  admin_username           = var.windows_admin_username
  admin_password           = random_password.windows_admin_password.result
  enable_automatic_updates = false # We want to control patching via Azure Update Management

  computer_name = "win${var.project_prefix}01"
  # Example: if project_prefix="patchlab", this becomes "winpatchlab01" (13 chars)

  network_interface_ids = [
    azurerm_network_interface.nic_windows.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 128
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter" # Or "2022-Datacenter"
    version   = "latest"
  }

  # Dynatrace OneAgent Deployment (Conceptual via Custom Data)
  custom_data = base64encode(templatefile("${path.module}/scripts/install_dynatrace_windows.ps1", {
    dynatrace_environment_url = var.dynatrace_environment_url
    dynatrace_api_token       = var.dynatrace_api_token
    vm_name                   = "win-vm-${var.project_prefix}-app01"
  }))

  tags = merge(azurerm_resource_group.rg_patch_lab.tags, {
    os_type  = "Windows"
    app_tier = "Application"
  })
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

# --- Associate RHEL VMs with the Data Collection Rule ---
resource "azurerm_monitor_data_collection_rule_association" "rhel_dcr_association" {
  count                   = var.rhel_vm_count
  name                    = "dcr-assc-rhel-vm-${format("%02d", count.index + 1)}"
  target_resource_id      = azurerm_linux_virtual_machine.rhel_vm[count.index].id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.vm_insights_dcr.id
  description             = "Association for RHEL VM ${count.index + 1} to VM Insights DCR."
}

# --- Associate Windows VM with the Data Collection Rule ---
resource "azurerm_monitor_data_collection_rule_association" "windows_dcr_association" {
  name                    = "dcr-assc-windows-vm-${var.project_prefix}" # Added project_prefix for uniqueness
  target_resource_id      = azurerm_windows_virtual_machine.windows_vm.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.vm_insights_dcr.id
  description             = "Association for Windows VM to VM Insights DCR."
}

# --- Azure Monitor: Log Analytics Workspace and VM Insights ---
resource "azurerm_log_analytics_workspace" "log_workspace" {
  name                = "law-${var.project_prefix}-monitoring"
  location            = azurerm_resource_group.rg_patch_lab.location
  resource_group_name = azurerm_resource_group.rg_patch_lab.name
  sku                 = "PerGB2018" # Or "Consumption"

  tags = azurerm_resource_group.rg_patch_lab.tags
}

# --- Data Collection Endpoint (DCE) ---
# A Data Collection Endpoint is required for Azure Monitor Agent (AMA)
# to ingest data using Data Collection Rules.
resource "azurerm_monitor_data_collection_endpoint" "vm_insights_dce" {
  name                          = "dce-${var.project_prefix}-vmi"
  resource_group_name           = azurerm_resource_group.rg_patch_lab.name
  location                      = azurerm_resource_group.rg_patch_lab.location
  public_network_access_enabled = true # Set to false if using Private Link/VNet integration

  # You might want to add tags here as well
  tags = azurerm_resource_group.rg_patch_lab.tags
}

resource "azurerm_monitor_data_collection_rule" "vm_insights_dcr" {
  name                = "dcr-${var.project_prefix}-vmi"
  resource_group_name = azurerm_resource_group.rg_patch_lab.name
  location            = azurerm_resource_group.rg_patch_lab.location

  description = "DCR for VM Insights data collection for ${var.project_prefix} lab."

  data_flow {
    streams      = ["Microsoft-Heartbeat", "Microsoft-Perf", "Microsoft-Syslog", "Microsoft-WindowsEvent", "Microsoft-InsightsMetrics"]
    destinations = ["log_analytics_destination"]
  }

  data_sources {
    performance_counter {
      name                          = "vminsights-PerfCounters"
      streams                       = ["Microsoft-Perf"]
      sampling_frequency_in_seconds = 60
      counter_specifiers = [
        "\\Processor(_Total)\\% Processor Time",
        "\\Memory\\Available MBytes",
        "\\LogicalDisk(_Total)\\% Free Space",
        "\\LogicalDisk(_Total)\\Avg. Disk sec/Read",
        "\\LogicalDisk(_Total)\\Avg. Disk sec/Write",
        "\\Network Interface(*)\\Bytes Total/sec"
      ]
    }

    syslog {
      name           = "vminsights-Syslog"
      streams        = ["Microsoft-Syslog"]
      facility_names = ["auth", "authpriv", "cron", "daemon", "mark", "kern", "local0", "local1", "local2", "local3", "local4", "local5", "local6", "local7", "lpr", "mail", "news", "syslog", "user", "uucp"]
      log_levels     = ["Alert", "Critical", "Emergency", "Error", "Info", "Notice", "Warning"]
    }

    windows_event_log {
      name           = "vminsights-WinEvents"
      streams        = ["Microsoft-WindowsEvent"]
      x_path_queries = ["Event!*[System[(Level=1 or Level=2 or Level=3)]]"]
    }

    # CRITICAL FIXES BASED ON YOUR PROVIDED DOCS:
    # 1. Using `extension_json` instead of `extension_settings_json`.
    # 2. Removing `input_enabled`.
    # 3. Configuring the AMA with the DCE and DCR rule ID via `extension_json`.
    extension {
      name           = "vminsights-Extension"
      streams        = ["Microsoft-Heartbeat", "Microsoft-InsightsMetrics"]
      extension_name = "MicrosoftMonitoringAgent" # This is the Azure Monitor Agent
      extension_json = jsonencode({
        "dataCollectionEndpoint" = {
          "endpoint" = azurerm_monitor_data_collection_endpoint.vm_insights_dce.logs_ingestion_endpoint
        }
      })
      # input_data_sources can be added here if needed to specify which other data sources feed this extension
      # e.g., input_data_sources = ["vminsights-PerfCounters", "vminsights-WinEvents"]
    }
  } # End of data_sources block

  destinations {
    log_analytics {
      name                  = "log_analytics_destination"
      workspace_resource_id = azurerm_log_analytics_workspace.log_workspace.id
    }
  } # End of destinations block

  tags = azurerm_resource_group.rg_patch_lab.tags
}


# --- RBAC Control (Example: Assigning a role to a user or service principal) ---
# For a lab, you'd typically either:
# 1. Use your own user account (already has permissions from your subscription access).
# 2. Create a dummy user/group in Azure AD *before* running Terraform and get its Object ID.
# 3. Use the `azuread` provider to query for existing users/groups.

# IMPORTANT: You need to have permissions to create role assignments for the identity
# running `terraform apply`.

# Example of fetching an Azure AD user by UPN (User Principal Name)
# Uncomment this block AND the 'azuread' provider at the top if you want to use this.
/*
data "azuread_user" "lab_engineer" {
  user_principal_name = var.rbac_lab_user_upn
}
*/

# Example of assigning a role to a specific user (using the data block above)
# You could also assign to a hardcoded principal_id for a known Service Principal
# that might represent a monitoring tool or automation account.
/*
resource "azurerm_role_assignment" "monitoring_reader_role" {
  scope                = azurerm_resource_group.rg_patch_lab.id
  role_definition_name = "Monitoring Reader" # Allows reading monitoring data
  principal_id         = data.azuread_user.lab_engineer.object_id
  description          = "Monitoring Reader role for a lab engineer account for observability."
}
*/

# For this lab, let's assume the identity running Terraform has necessary permissions
# and we'll skip creating new users/groups via Terraform for simplicity.
# If you want to demonstrate this, uncomment the blocks above and define `var.rbac_lab_user_upn`.

# --- Azure Policy Assignment for Update Management Center ---
# This policy assigns the "Configure machines to receive Azure automatic VM guest OS patches by platform"
# policy definition. This essentially enrolls your VMs into a state where Azure can automatically
# assess and potentially apply patches, or at least prepare them for the new Update Management Center.
# This does NOT create a schedule, but makes the VMs visible and manageable by the UMC.
# You will still need to use the Azure Portal's Update Management Center to define patch schedules
# and target your VMs for compliance and deployment.

resource "azurerm_resource_group_policy_assignment" "vm_update_assessment_policy" {
  name                 = "Enable-VM-Update-Assessment-For-${var.project_prefix}"
  resource_group_id    = azurerm_resource_group.rg_patch_lab.id # CORRECTED: Assign to this specific resource group
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/8a42f63f-67a5-4b05-924b-325d0c2e3915"
  display_name         = "Configure machines to receive Azure automatic VM guest OS patches by platform for ${var.project_prefix} Lab"
  description          = "Assigns a policy to enable automatic VM guest OS patching assessment for this lab environment."

  parameters = jsonencode({
    "assignmentType" = {
      "value" = "Audit" # Change to "ApplyAndAutoCorrect" to have Azure automatically patch
    }
  })
}
