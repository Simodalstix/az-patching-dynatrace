# outputs.tf

output "resource_group_name" {
  description = "The name of the created resource group."
  value       = azurerm_resource_group.rg_patch_lab.name
}

output "vnet_name" {
  description = "The name of the created Virtual Network."
  value       = azurerm_virtual_network.vnet_lab.name
}

output "load_balancer_public_ip" {
  description = "Public IP address of the Azure Load Balancer."
  value       = azurerm_public_ip.pip_lb.ip_address
}

output "windows_vm_public_ip" {
  description = "Public IP address of the Windows Server VM (for direct RDP access)."
  value       = azurerm_public_ip.pip_windows.ip_address
}

output "linux_admin_password" {
  description = "Admin password for Linux VMs. Store securely!"
  value       = "${var.linux_admin_password_prefix}${random_string.rhel_password_suffix.result}"
  sensitive   = true
}

output "windows_admin_password" {
  description = "Admin password for the Windows Server VM. Store securely!"
  value       = random_password.windows_admin_password.result
  sensitive   = true
}

output "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics Workspace."
  value       = azurerm_log_analytics_workspace.log_workspace.id
}

output "log_analytics_workspace_name" {
  description = "The name of the Log Analytics Workspace."
  value       = azurerm_log_analytics_workspace.log_workspace.name
}
