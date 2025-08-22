output "vnet_name" {
  value = azurerm_virtual_network.this.name
}

output "vnet_id" {
  value = azurerm_virtual_network.this.id
}

output "web_subnet_id" {
  value = azurerm_subnet.web.id
}

output "app_subnet_id" {
  value = azurerm_subnet.app.id
}

output "lb_backend_pool_id" {
  value = azurerm_lb_backend_address_pool.web.id
}

output "lb_public_ip" {
  value = azurerm_public_ip.lb.ip_address
}