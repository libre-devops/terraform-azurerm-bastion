output "ids" {
  description = "Map of bastion name to resource id."
  value       = module.bastion.ids
}

output "ids_zipmap" {
  description = "Map of bastion name to { name, id }."
  value       = module.bastion.ids_zipmap
}

output "dns_names" {
  description = "Map of bastion name to DNS name."
  value       = module.bastion.dns_names
}

output "private_only" {
  description = "Map of bastion name to private-only status."
  value       = module.bastion.private_only
}
