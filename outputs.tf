# Root Outputs
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

# Windows Outputs
output "windows_vm_public_ip" {
  description = "Public IP address of the Windows Server VM (for direct RDP access)."
  value       = module.windows_vm.public_ip
}

output "windows_admin_password" {
  description = "Admin password for the Windows Server VM. Store securely!"
  value       = module.windows_vm.admin_password
  sensitive   = true
}

# Linux Outputs
output "linux_admin_password" {
  description = "Admin password for Linux VMs. Store securely!"
  value       = module.rhel_vms.admin_password
  sensitive   = true
}

# Monitoring Outputs
output "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics Workspace."
  value       = module.monitoring.log_analytics_workspace_id
}

output "log_analytics_workspace_name" {
  description = "The name of the Log Analytics Workspace."
  value       = module.monitoring.log_analytics_workspace_name
}
