locals {
  rg      = provider::azurerm::parse_resource_id(var.resource_group_id)
  rg_name = local.rg.resource_group_name

  # Which per-SKU capabilities each host may use; preconditions assert against these so a mismatch
  # fails the plan with a real message instead of an API error.
  standard_plus = { for k, b in var.bastion_hosts : k => contains(["Standard", "Premium"], b.sku) }
}

# Bastion hosts. Developer (the default) attaches straight to a virtual network: no
# AzureBastionSubnet, no public IP, no scale units, free. The paid SKUs take an ip_configuration
# whose public_ip_address_id comes from the public-ip module (this module never creates public IPs).
resource "azurerm_bastion_host" "this" {
  for_each = var.bastion_hosts

  resource_group_name = local.rg_name
  location            = var.location
  tags                = merge(var.tags, coalesce(each.value.tags, {}))
  name                = each.key

  sku                = each.value.sku
  virtual_network_id = each.value.sku == "Developer" ? each.value.virtual_network_id : null
  scale_units        = each.value.scale_units
  zones              = each.value.zones

  copy_paste_enabled        = each.value.copy_paste_enabled
  file_copy_enabled         = each.value.file_copy_enabled
  ip_connect_enabled        = each.value.ip_connect_enabled
  kerberos_enabled          = each.value.kerberos_enabled
  shareable_link_enabled    = each.value.shareable_link_enabled
  tunneling_enabled         = each.value.tunneling_enabled
  session_recording_enabled = each.value.session_recording_enabled

  dynamic "ip_configuration" {
    for_each = each.value.sku != "Developer" && each.value.ip_configuration != null ? [each.value.ip_configuration] : []
    content {
      name                 = ip_configuration.value.name
      subnet_id            = ip_configuration.value.subnet_id
      public_ip_address_id = ip_configuration.value.public_ip_address_id
    }
  }

  lifecycle {
    precondition {
      condition     = each.value.sku != "Developer" || each.value.virtual_network_id != null
      error_message = "Bastion \"${each.key}\": the Developer SKU attaches to a virtual network; set virtual_network_id."
    }
    precondition {
      condition     = each.value.sku == "Developer" || each.value.ip_configuration != null
      error_message = "Bastion \"${each.key}\": the ${each.value.sku} SKU needs ip_configuration (an AzureBastionSubnet of /26 or larger, plus a public_ip_address_id from the public-ip module${each.value.sku == "Premium" ? ", or omit the public IP for a private-only bastion" : ""})."
    }
    precondition {
      condition     = contains(["Premium", "Developer"], each.value.sku) || try(each.value.ip_configuration.public_ip_address_id, null) != null
      error_message = "Bastion \"${each.key}\": public_ip_address_id is required for the ${each.value.sku} SKU (only Premium supports private-only)."
    }
    precondition {
      condition     = each.value.scale_units == null || local.standard_plus[each.key]
      error_message = "Bastion \"${each.key}\": scale_units is only configurable on Standard or Premium."
    }
    precondition {
      condition = local.standard_plus[each.key] || alltrue([
        each.value.file_copy_enabled == null,
        each.value.ip_connect_enabled == null,
        each.value.kerberos_enabled == null,
        each.value.shareable_link_enabled == null,
        each.value.tunneling_enabled == null,
      ])
      error_message = "Bastion \"${each.key}\": file_copy, ip_connect, kerberos, shareable_link, and tunneling need the Standard or Premium SKU."
    }
    precondition {
      condition     = each.value.session_recording_enabled == null || each.value.sku == "Premium"
      error_message = "Bastion \"${each.key}\": session_recording_enabled needs the Premium SKU."
    }
    precondition {
      condition     = each.value.zones == null || local.standard_plus[each.key]
      error_message = "Bastion \"${each.key}\": zones are only supported on Standard or Premium."
    }
  }
}
