resource "azurerm_linux_virtual_machine" "this" {
  count                           = var.vm_count
  name                            = "${var.name_prefix}-${format("%02d", count.index + 1)}"
  resource_group_name             = var.resource_group_name
  location                        = var.location
  size                            = var.size
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false

  identity {
    type = "SystemAssigned"
  }

  availability_set_id = var.avset_id
  network_interface_ids = [
    var.nic_ids[count.index]
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = var.disk_size
  }

  source_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "9-LVM"
    version   = "latest"
  }

  custom_data = base64encode(templatefile("${path.module}/../../scripts/install_dynatrace_rhel.sh", {
    dynatrace_environment_url = var.dynatrace_environment_url
    dynatrace_api_token       = var.dynatrace_api_token
    vm_name                   = "${var.name_prefix}-${format("%02d", count.index + 1)}"
  }))

  tags = var.tags
}
