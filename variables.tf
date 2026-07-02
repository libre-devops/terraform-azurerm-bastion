variable "resource_group_id" {
  description = "Resource id of the resource group to create the bastion hosts in. The name is parsed from it (pass the rg module's ids output)."
  type        = string

  validation {
    condition     = try(provider::azurerm::parse_resource_id(var.resource_group_id).resource_type, "") == "resourceGroups"
    error_message = "resource_group_id must be a resource group id of the form /subscriptions/<sub>/resourceGroups/<name>."
  }
}

variable "location" {
  description = "Azure region for the bastion hosts."
  type        = string
}

variable "tags" {
  description = "Tags applied to every bastion host (merged with any per-host tags)."
  type        = map(string)
  default     = {}
}

variable "bastion_hosts" {
  description = <<DESC
The bastion hosts to create, keyed by name. The default SKU is DEVELOPER: the lightweight (free)
shared-pool offering that just attaches to a virtual network (set virtual_network_id), needs no
AzureBastionSubnet, no public IP, and no scale units, so getting going is one attribute. Scale up per
host by setting sku:

- Basic: needs ip_configuration { subnet_id (an AzureBastionSubnet, /26 or larger), and a
  public_ip_address_id from the public-ip module (this module never creates public IPs) }.
- Standard: Basic plus scale_units (2-50) and the optional features file_copy_enabled,
  ip_connect_enabled, kerberos_enabled, shareable_link_enabled, tunneling_enabled.
- Premium: Standard plus session_recording_enabled, and public_ip_address_id may be omitted for a
  private-only bastion.

copy_paste_enabled works on every SKU (default true). zones is supported on Standard and Premium.
Feature/SKU mismatches fail the plan with a specific message rather than at the API.
DESC

  type = map(object({
    sku                = optional(string, "Developer")
    virtual_network_id = optional(string)

    ip_configuration = optional(object({
      name                 = optional(string, "bastion-ipconfig")
      subnet_id            = string
      public_ip_address_id = optional(string)
    }))

    scale_units = optional(number)
    zones       = optional(list(string))

    copy_paste_enabled        = optional(bool, true)
    file_copy_enabled         = optional(bool)
    ip_connect_enabled        = optional(bool)
    kerberos_enabled          = optional(bool)
    shareable_link_enabled    = optional(bool)
    tunneling_enabled         = optional(bool)
    session_recording_enabled = optional(bool)

    tags = optional(map(string))
  }))
  default = {}

  validation {
    condition     = alltrue([for b in values(var.bastion_hosts) : contains(["Developer", "Basic", "Standard", "Premium"], b.sku)])
    error_message = "sku must be Developer, Basic, Standard, or Premium."
  }

  validation {
    condition     = alltrue([for b in values(var.bastion_hosts) : b.scale_units == null || (coalesce(b.scale_units, 2) >= 2 && coalesce(b.scale_units, 2) <= 50)])
    error_message = "scale_units, when set, must be between 2 and 50."
  }
}
