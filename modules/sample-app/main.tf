# Simple web app deployment script for Linux VMs
resource "azurerm_virtual_machine_extension" "web_app" {
  count                = length(var.linux_vm_ids)
  name                 = "install-webapp-${count.index}"
  virtual_machine_id   = var.linux_vm_ids[count.index]
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"

  settings = jsonencode({
    script = base64encode(templatefile("${path.module}/scripts/install_webapp.sh", {
      vm_index = count.index
    }))
  })

  tags = var.tags
}

# Application Insights for monitoring
resource "azurerm_application_insights" "main" {
  name                = "ai-${var.project_prefix}-webapp"
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = var.log_analytics_workspace_id
  application_type    = "web"

  tags = var.tags
}