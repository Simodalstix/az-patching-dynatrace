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

variable "linux_vm_ids" {
  type        = list(string)
  description = "List of Linux VM IDs"
}

variable "windows_vm_ids" {
  type        = list(string)
  description = "List of Windows VM IDs"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Resource tags"
}