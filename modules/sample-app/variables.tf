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

variable "log_analytics_workspace_id" {
  type        = string
  description = "Log Analytics Workspace ID"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Resource tags"
}