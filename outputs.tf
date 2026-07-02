output "bastion_hosts" {
  description = "The bastion hosts, keyed by name. Full resource objects (all attributes)."
  value       = azurerm_bastion_host.this
}

output "ids" {
  description = "Map of bastion name to resource id."
  value       = { for k, b in azurerm_bastion_host.this : k => b.id }
}

output "ids_zipmap" {
  description = "Map of bastion name to { name, id }, for easy composition with other modules."
  value       = { for k, b in azurerm_bastion_host.this : k => { name = b.name, id = b.id } }
}

output "names" {
  description = "Map of bastion name to name (convenience passthrough)."
  value       = { for k, b in azurerm_bastion_host.this : k => b.name }
}

output "dns_names" {
  description = "Map of bastion name to the bastion DNS name."
  value       = { for k, b in azurerm_bastion_host.this : k => b.dns_name }
}

output "private_only" {
  description = "Map of bastion name to whether the host is private-only (Premium without a public IP)."
  value       = { for k, b in azurerm_bastion_host.this : k => b.private_only_enabled }
}

output "resource_group_name" {
  description = "The resource group the bastion hosts live in, parsed from resource_group_id."
  value       = local.rg_name
}
