output "bas_hostname" {
  value       = azurerm_bastion_host.bas_host.name
  description = "The host name of the bastion"
}

output "bas_nsg_id" {
  value       = azurerm_network_security_group.bas_nsg.id
  description = "The host name of the bastion"
}

output "bas_nsg_name" {
  value       = azurerm_network_security_group.bas_nsg.name
  description = "The name of the bastion nsg"
}

output "bas_subnet_id" {
  value       = azurerm_subnet.bas_subnet.id
  description = "The host name of the bastion"
}

output "bas_subnet_ip_range" {
  value       = azurerm_subnet.bas_subnet.address_prefixes
  description = "Bastion subnet IP range"
}

output "bas_subnet_name" {
  value       = azurerm_subnet.bas_subnet.name
  description = "The subnet name of the Azure Bastion subnet"
}
