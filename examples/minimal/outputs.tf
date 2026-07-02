output "ids" {
  description = "Map of bastion name to resource id."
  value       = module.bastion.ids
}

output "dns_names" {
  description = "Map of bastion name to DNS name."
  value       = module.bastion.dns_names
}
