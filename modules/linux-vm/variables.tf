variable "vm_count" {
  type        = number
  description = "Number of VMs to create"
}

variable "name_prefix" {
  type        = string
  description = "Prefix for VM names"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "size" {
  type        = string
  description = "VM size"
}

variable "admin_username" {
  type        = string
  description = "Admin username"
}

variable "admin_password" {
  type        = string
  sensitive   = true
  description = "Admin password"
}

variable "avset_id" {
  type        = string
  description = "Availability set ID"
}

variable "nic_ids" {
  type        = list(string)
  description = "List of NIC IDs"
}

variable "disk_size" {
  type        = number
  description = "OS disk size in GB"
}

variable "dynatrace_environment_url" {
  type        = string
  sensitive   = true
  description = "Dynatrace environment URL"
}

variable "dynatrace_api_token" {
  type        = string
  sensitive   = true
  description = "Dynatrace API token"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Resource tags"
}
