variable "name_prefix" {}
variable "location" {}
variable "resource_group_name" {}
variable "size" {}
variable "admin_username" {}
variable "admin_password" {}
variable "disk_size" {
  default = 128
}
variable "public_ip" {

}
variable "nic_id" {}
variable "avset_id" {}
variable "dynatrace_environment_url" {}
variable "dynatrace_api_token" {}
variable "tags" {
  type    = map(string)
  default = {}
}
