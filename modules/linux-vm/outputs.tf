output "admin_password" {
  description = "Admin password for the Linux VMs"
  value       = var.admin_password
  sensitive   = true
}
output "vm_ids" {
  description = "List of Linux VM IDs"
  value       = azurerm_linux_virtual_machine.this[*].id
}
