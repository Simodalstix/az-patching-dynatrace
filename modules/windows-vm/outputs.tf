output "admin_password" {
  description = "Admin password for the Windows VM"
  value       = var.admin_password
  sensitive   = true
}

output "public_ip" {
  description = "Public IP of the Windows VM"
  value       = var.public_ip
}
