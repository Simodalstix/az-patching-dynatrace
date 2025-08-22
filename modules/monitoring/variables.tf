variable "vm_ids" {
  type        = list(string)
  description = "List of VM resource IDs to associate with the DCR"
}

variable "project_prefix" {
  type        = string
  description = "Prefix for naming convention"
}

variable "location" {
  type        = string
  description = "Azure region for all resources"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group to deploy monitoring resources into"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Optional tags to apply to all resources"
}

variable "alert_email" {
  type        = string
  description = "Email address for alerts"
  default     = "admin@example.com"
}
