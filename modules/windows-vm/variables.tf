variable "name_prefix" {
  type        = string
  description = "Prefix for VM name"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name"
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

variable "disk_size" {
  type        = number
  default     = 128
  description = "OS disk size in GB"
}

variable "public_ip" {
  type        = string
  description = "Public IP address"
}

variable "nic_id" {
  type        = string
  description = "Network interface ID"
}

variable "avset_id" {
  type        = string
  description = "Availability set ID"
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
