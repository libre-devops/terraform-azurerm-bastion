variable "bas_host_ipconfig_name" {
  type        = string
  description = "The IP Configuration name for the Azure Bastion"
}

variable "bas_host_location" {
  type        = string
  description = "The location for the bastion host, default is UK South"
}

variable "bas_host_name" {
  type        = string
  description = "The name for the Bastion host in the portal"
}

variable "bas_host_rg_name" {
  type        = string
  description = "The resource group name for the Bastion resource"
}

variable "bas_nsg_location" {
  type        = string
  description = "The location of the bastion nsg"
}

variable "bas_nsg_name" {
  type        = string
  description = "The name for the NSG to be created with the AzureBastionSubnet"
}

variable "bas_nsg_rg_name" {
  description = "The resource group name which the NSG should be placed in"
}

variable "bas_pip_allocation_method" {
  default     = "Static"
  description = "The allocation method for the Public IP, default is Static"
}

variable "bas_pip_location" {
  type        = string
  description = "The location for the Bastion Public IP, default is UK South"
}

variable "bas_pip_name" {
  type        = string
  description = "The name for the Bastion Public IP"
}

variable "bas_pip_rg_name" {
  type        = string
  description = "The resource group name for Bastion Public IP"
}

variable "bas_pip_sku" {
  type        = string
  default     = "Standard"
  description = "The SKU for the Bastion Public IP, default is Standard"
}

variable "bas_subnet_iprange" {
  type        = string
  description = "The IP Range for the Bastion Subnet - Note, Minimum is a /28"
}

variable "bas_subnet_name" {
  default     = "AzureBastionSubnet"
  type        = string
  description = "The name of the Azure Bastion Subnet - note, this is a static value and should not be changed"
}

variable "copy_paste_enabled" {
  type        = bool
  description = "Whether copy paste is enabled, defaults to true"
  default     = true
}

variable "file_copy_enabled" {
  type        = bool
  description = "Whether file copy is enabled"
  default     = null
}

variable "ip_connect_enabled" {
  type        = bool
  description = "Whether the IP connect feature is enabled"
  default     = null
}

variable "scale_units" {
  type        = number
  description = "The number of scale units, default is 2"
  default     = 2
}

variable "shareable_link_enabled" {
  type        = bool
  description = "Whether the shareable link is enabled"
  default     = null
}

variable "sku" {
  type        = string
  description = "The SKU of the bastion, default is Basic"
  default     = "Basic"
}

variable "tags" {
  description = "The default tags to be assigned"
  type        = map(any)
}

variable "tunneling_enabled" {
  type        = bool
  description = "Whether the tunneling feature is enable"
  default     = null
}

variable "vnet_name" {
  type        = string
  description = "The name of the VNet the bastion is intended to join"
}

variable "vnet_rg_name" {
  type        = string
  description = "The name of the resource group that the VNet can be found int"
}
