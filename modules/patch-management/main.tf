# Maintenance Configuration for Patch Management
resource "azurerm_maintenance_configuration" "patch_config" {
  name                = "mc-${var.project_prefix}-patches"
  resource_group_name = var.resource_group_name
  location            = var.location
  scope               = "InGuestPatch"

  window {
    start_date_time      = "2024-01-01 02:00"
    duration             = "03:00"
    time_zone            = "Australia/Sydney"
    recur_every          = "1Week Sunday"
  }

  install_patches {
    linux {
      classifications_to_include = ["Critical", "Security", "Other"]
      package_names_mask_to_exclude = ["kernel*"]
    }
    windows {
      classifications_to_include = ["Critical", "Security", "UpdateRollup", "FeaturePack", "ServicePack", "Definition", "Tools", "Updates"]
      kb_numbers_to_exclude = []
    }
    reboot = "IfRequired"
  }

  tags = var.tags
}

# Maintenance Assignment for Linux VMs
resource "azurerm_maintenance_assignment_virtual_machine" "linux_patch_assignment" {
  count                        = length(var.linux_vm_ids)
  location                     = var.location
  maintenance_configuration_id = azurerm_maintenance_configuration.patch_config.id
  virtual_machine_id           = var.linux_vm_ids[count.index]
}

# Maintenance Assignment for Windows VM
resource "azurerm_maintenance_assignment_virtual_machine" "windows_patch_assignment" {
  count                        = length(var.windows_vm_ids)
  location                     = var.location
  maintenance_configuration_id = azurerm_maintenance_configuration.patch_config.id
  virtual_machine_id           = var.windows_vm_ids[count.index]
}