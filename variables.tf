# variables.tf

variable "location" {
  description = "The Azure region where resources will be deployed."
  type        = string
  default     = "Australia East"
}

variable "project_prefix" {
  description = "A short prefix for resource naming to ensure uniqueness and organization."
  type        = string
  default     = "simo"
}

variable "resource_group_name" {
  description = "The name of the resource group to create."
  type        = string
  default     = "rg-patchlab-infra"
}


variable "vnet_address_space" {
  description = "The address space for the virtual network."
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_web_address_prefix" {
  description = "The address prefix for the web subnet."
  type        = string
  default     = "10.0.1.0/24"
}

variable "subnet_app_address_prefix" {
  description = "The address prefix for the application subnet."
  type        = string
  default     = "10.0.2.0/24"
}

variable "rhel_vm_count" {
  description = "Number of RHEL virtual machines to create."
  type        = number
  default     = 2 # 2 RHEL VMs for the web tier
}

variable "linux_admin_username" {
  description = "Admin username for Linux VMs."
  type        = string
  default     = "azureuser"
}

variable "linux_admin_password_prefix" {
  description = "Password prefix for Linux VMs. A random suffix will be added."
  type        = string
  sensitive   = true
  default     = ""
}

variable "windows_admin_username" {
  description = "Admin username for Windows VM."
  type        = string
  default     = "azureadmin"
}

variable "allowed_source_ip_for_ssh" {
  description = "Your public IP address or CIDR range allowed for SSH access. IMPORTANT: Replace 0.0.0.0/0 with your actual IP for security."
  type        = string
  default     = "0.0.0.0/0" # WARNING: Insecure for production. Replace with actual public IP/range.
}

variable "allowed_source_ip_for_rdp" {
  description = "Your public IP address or CIDR range allowed for RDP access. IMPORTANT: Replace 0.0.0.0/0 with your actual IP for security."
  type        = string
  default     = "0.0.0.0/0" # WARNING: Insecure for production. Replace with actual public IP/range.
}

variable "dynatrace_environment_url" {
  description = "Your Dynatrace Environment URL (e.g., https://yourtenant.live.dynatrace.com)."
  type        = string
  sensitive   = true
  default     = ""
}

variable "dynatrace_api_token" {
  description = "Your Dynatrace API Token with 'Installer download' and 'Agent monitoring' permissions."
  type        = string
  sensitive   = true
  default     = "" # Set this in your terraform.tfvars or environment variables
}

variable "environment" {
  type    = string
  default = "dev"
}
# Optional: For RBAC demonstration
/*
variable "rbac_lab_user_upn" {
  description = "User Principal Name (UPN) of an Azure AD user to assign RBAC roles to for lab demonstration."
  type        = string
  default     = "your.user@yourtenant.onmicrosoft.com" # REPLACE with an actual dummy user or your own UPN
}
*/
