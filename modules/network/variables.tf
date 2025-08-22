variable "project_prefix" {
  type        = string
  description = "Prefix for resource naming"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name"
}

variable "vnet_address_space" {
  type        = string
  description = "VNet address space"
}

variable "subnet_web_address_prefix" {
  type        = string
  description = "Web subnet address prefix"
}

variable "subnet_app_address_prefix" {
  type        = string
  description = "App subnet address prefix"
}

variable "allowed_source_ip_for_ssh" {
  type        = string
  description = "Allowed IP for SSH access"
}

variable "allowed_source_ip_for_rdp" {
  type        = string
  description = "Allowed IP for RDP access"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Resource tags"
}