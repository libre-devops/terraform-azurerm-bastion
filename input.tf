variable "vnet_name" {
  type        = string
  description = "The name of the VNet the bastion is intended to join"
}

variable "bas_subnet_name" {
  default     = "AzureBastionSubnet"
  type        = string
  description = "The name of the Azure Bastion Subnet - note, this is a static value and should not be changed"
  validation {
    condition     = var.bas_subnet_name != "AzureBastionSubnet"
    error_message = "Subnet Name is invalid."
  }
}

variable "bas_subnet_iprange" {
  type        = string
  description = "The IP Range for the Bastion Subnet - Note, Minimum is a /28"
}

variable "bas_nsg_name" {
  type        = string
  description = "The name for the NSG to be created with the AzureBastionSubnet"
}

variable "bas_nsg_location" {
  type        = string
  description = "The location of the bastion nsg"
}

variable "bas_nsg_rg_name" {
  description = "The resource group name which the NSG should be placed in"
}

variable "tags" {
  description = "The default tags to be assigned"
  type        = map(any)
}

variable "vnet_rg_name" {
  type        = string
  description = "The name of the resource group that the VNet can be found int"
}

variable "bas_pip_name" {
  type        = string
  description = "The name for the Bastion Public IP"
}

variable "bas_pip_location" {
  type        = string
  description = "The location for the Bastion Public IP, default is UK South"
}

variable "bas_pip_rg_name" {
  type        = string
  description = "The resource group name for Bastion Public IP"
}

variable "bas_pip_allocation_method" {
  default     = "Static"
  description = "The allocation method for the Public IP, default is Static"
}

variable "bas_pip_sku" {
  type        = string
  default     = "Standard"
  description = "The SKU for the Bastion Public IP, default is Standard"
}

variable "bas_host_name" {
  type        = string
  description = "The name for the Bastion host in the portal"
}

variable "bas_host_location" {
  type        = string
  description = "The location for the bastion host, default is UK South"
}

variable "bas_host_rg_name" {
  type        = string
  description = "The resource group name for the Bastion resource"
}

variable "bas_host_ipconfig_name" {
  type        = string
  description = "The IP Configuration name for the Azure Bastion"
}