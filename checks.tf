# check blocks run after every plan and apply and warn (without blocking) on configuration that would
# quietly misbehave.

# The module does nothing without at least one host.
check "creates_at_least_one_bastion" {
  assert {
    condition     = length(var.bastion_hosts) > 0
    error_message = "No bastion hosts would be created: set bastion_hosts."
  }
}

# A virtual_network_id on a paid SKU is ignored (the attachment comes from ip_configuration).
check "vnet_id_only_matters_for_developer" {
  assert {
    condition     = alltrue([for k, b in var.bastion_hosts : !(b.sku != "Developer" && b.virtual_network_id != null)])
    error_message = "These hosts set virtual_network_id on a non-Developer SKU, where it is ignored (the paid SKUs attach via ip_configuration): ${join(", ", sort([for k, b in var.bastion_hosts : k if b.sku != "Developer" && b.virtual_network_id != null]))}."
  }
}
