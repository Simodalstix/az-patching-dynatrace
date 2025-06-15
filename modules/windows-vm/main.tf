resource "azurerm_windows_virtual_machine" "this" {
  name                = "${var.name_prefix}-app01"
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.size
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  identity {
    type = "SystemAssigned"
  }

  network_interface_ids = [var.nic_id]

  availability_set_id = var.avset_id

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = var.disk_size
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter" # or 2022-Datacenter if you like
    version   = "latest"
  }

  patch_mode = "AutomaticByPlatform"

  computer_name = "${var.name_prefix}01"

  custom_data = base64encode(templatefile("${path.module}/../../scripts/install_dynatrace_windows.ps1", {
    dynatrace_environment_url = var.dynatrace_environment_url
    dynatrace_api_token       = var.dynatrace_api_token
    vm_name                   = "${var.name_prefix}-app01"
  }))

  tags = var.tags
}
