resource "azurerm_subnet" "bas_subnet" {
  name                 = var.bas_subnet_name
  resource_group_name  = var.vnet_rg_name
  virtual_network_name = var.vnet_name
  address_prefixes     = [var.bas_subnet_iprange]

  timeouts {
    create = "5m"
    delete = "10m"
  }
}

resource "azurerm_public_ip" "bas_pip" {
  name                = var.bas_pip_name
  location            = var.bas_pip_location
  resource_group_name = var.bas_pip_rg_name
  allocation_method   = var.bas_pip_allocation_method
  sku                 = var.bas_pip_sku
  tags                = var.tags
}

resource "azurerm_bastion_host" "bas_host" {
  name                = var.bas_host_name
  location            = var.bas_host_location
  resource_group_name = var.bas_host_rg_name

  ip_configuration {
    name                 = var.bas_host_ipconfig_name
    subnet_id            = azurerm_subnet.bas_subnet.id
    public_ip_address_id = azurerm_public_ip.bas_pip.id
  }

  tags = var.tags
}

resource "azurerm_network_security_group" "bas_nsg" {
  name                = var.bas_nsg_name
  location            = var.bas_nsg_location
  resource_group_name = var.bas_nsg_rg_name
  tags                = var.tags

  timeouts {
    create = "5m"
    delete = "10m"
  }
}

#Fix for https://github.com/terraform-providers/terraform-provider-azurerm/issues/5232
resource "azurerm_subnet_network_security_group_association" "bas_nsg_association" {

  subnet_id                 = azurerm_subnet.bas_subnet.id
  network_security_group_id = azurerm_network_security_group.bas_nsg.id

  depends_on = [azurerm_network_security_rule.bas_nsg]
}

// Fix error which causes security errors to be flagged by TFSec, public egress is needed for Azure Bastion to function, its kind of the point :)
#tfsec:ignore:azure-network-no-public-egress[destination_address_prefix="*"]
resource "azurerm_network_security_rule" "bas_nsg" {
  for_each = var.azure_bastion_nsg_list

  name                        = each.key
  priority                    = each.value.priority
  direction                   = each.value.direction
  access                      = each.value.access
  protocol                    = each.value.protocol
  source_port_range           = each.value.source_port
  destination_port_range      = each.value.destination_port
  source_address_prefix       = each.value.source_address_prefix

  #tfsec:ignore:azure-network-no-public-egress[destination_address_prefix="*"]
  destination_address_prefix  = each.value.destination_address_prefix

  resource_group_name         = var.bas_nsg_rg_name
  network_security_group_name = azurerm_network_security_group.bas_nsg.name
}

variable "azure_bastion_nsg_list" {
  default = {
    "AllowHttpsInbound"                       = { priority = "120", direction = "Inbound", source_port = "*", destination_port = "443", access = "Allow", protocol = "Tcp", source_address_prefix = "Internet", destination_address_prefix = "*" },
    "AllowGatewayManagerInbound"              = { priority = "130", direction = "Inbound", source_port = "*", destination_port = "443", access = "Allow", protocol = "Tcp", source_address_prefix = "GatewayManager", destination_address_prefix = "*" },
    "AllowAzureLoadBalancerInbound"           = { priority = "140", direction = "Inbound", source_port = "*", destination_port = "443", access = "Allow", protocol = "Tcp", source_address_prefix = "AzureLoadBalancer", destination_address_prefix = "*" },
    "AllowBastionHostCommunication1"          = { priority = "150", direction = "Inbound", source_port = "*", destination_port = "5701", access = "Allow", protocol = "Tcp", source_address_prefix = "VirtualNetwork", destination_address_prefix = "VirtualNetwork" },
    "AllowBastionHostCommunication2"          = { priority = "155", direction = "Inbound", source_port = "*", destination_port = "80", access = "Allow", protocol = "Tcp", source_address_prefix = "VirtualNetwork", destination_address_prefix = "VirtualNetwork" },
    "AllowSSHRDPOutbound1"                    = { priority = "160", direction = "Outbound", source_port = "*", destination_port = "22", access = "Allow", protocol = "Tcp", source_address_prefix = "*", destination_address_prefix = "VirtualNetwork" },
    "AllowSSHRDPOutbound2"                    = { priority = "165", direction = "Outbound", source_port = "*", destination_port = "3389", access = "Allow", protocol = "Tcp", source_address_prefix = "*", destination_address_prefix = "VirtualNetwork" },
    "AllowAzureCloudOutbound2"                = { priority = "170", direction = "Outbound", source_port = "*", destination_port = "443", access = "Allow", protocol = "Tcp", source_address_prefix = "*", destination_address_prefix = "AzureCloud" },
    "AllowAzureBastionCommunicationOutbound1" = { priority = "180", direction = "Outbound", source_port = "*", destination_port = "5701", access = "Allow", protocol = "Tcp", source_address_prefix = "VirtualNetwork", destination_address_prefix = "VirtualNetwork" },
    "AllowAzureBastionCommunicationOutbound2" = { priority = "185", direction = "Outbound", source_port = "*", destination_port = "8080", access = "Allow", protocol = "Tcp", source_address_prefix = "VirtualNetwork", destination_address_prefix = "VirtualNetwork" },
    "AllowGetSessionInformation"              = { priority = "190", direction = "Outbound", source_port = "*", destination_port = "80", access = "Allow", protocol = "Tcp", source_address_prefix = "*", destination_address_prefix = "*" },
  }
  description = "The Standard list of NSG rules needed to make a bastion work"
}