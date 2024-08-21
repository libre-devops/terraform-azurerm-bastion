locals {
  requires_external_subnet = var.create_bastion_subnet == false && var.external_subnet_id == null
}

resource "azurerm_subnet" "bastion_subnet" {
  count                = var.create_bastion_subnet == true ? 1 : 0
  name                 = try(var.bastion_subnet_name, "AzureBastionSubnet") # Must be AzureBastionSubnet
  resource_group_name  = try(var.bastion_subnet_target_vnet_rg_name, null)
  virtual_network_name = try(var.bastion_subnet_target_vnet_name, null)
  address_prefixes     = [var.bastion_subnet_range]

  timeouts {
    create = "5m"
    delete = "10m"
  }
}

resource "azurerm_network_security_group" "bastion_nsg" {
  count               = var.create_bastion_nsg == true ? 1 : 0
  name                = var.bastion_nsg_name != null ? var.bastion_nsg_name : "nsg-${var.bastion_host_name}"
  location            = var.bastion_nsg_location != null ? var.bastion_nsg_location : var.location
  resource_group_name = var.bastion_nsg_rg_name != null ? var.bastion_nsg_rg_name : var.rg_name
  tags                = var.tags

  timeouts {
    create = "5m"
    delete = "10m"
  }
}

// Fix error which causes security errors to be flagged by TFSec, public egress is needed for Azure Bastion to function, its kind of the point :)
#tfsec:ignore:azure-network-no-public-egress[destination_address_prefix="*"]
resource "azurerm_network_security_rule" "bastion_nsg" {
  for_each = var.create_bastion_nsg_rules == true && var.create_bastion_nsg == true ? var.azure_bastion_nsg_list : {}

  name                   = each.key
  priority               = each.value.priority
  direction              = each.value.direction
  access                 = each.value.access
  protocol               = each.value.protocol
  source_port_range      = each.value.source_port
  destination_port_range = each.value.destination_port
  source_address_prefix  = each.value.source_address_prefix

  #tfsec:ignore:azure-network-no-public-egress
  destination_address_prefix = each.value.destination_address_prefix

  resource_group_name         = azurerm_network_security_group.bastion_nsg[0].resource_group_name
  network_security_group_name = azurerm_network_security_group.bastion_nsg[0].name
}

#Fix for https://github.com/terraform-providers/terraform-provider-azurerm/issues/5232
resource "azurerm_subnet_network_security_group_association" "bastion_nsg_association" {
  count      = var.create_bastion_subnet == true && var.create_bastion_nsg == true ? 1 : 0
  depends_on = [azurerm_network_security_rule.bastion_nsg]

  subnet_id                 = azurerm_subnet.bastion_subnet[0].id
  network_security_group_id = azurerm_network_security_group.bastion_nsg[0].id
}

resource "azurerm_public_ip" "bastion_pip" {
  name                = var.bastion_pip_name != null ? var.bastion_pip_name : "pip-${var.bastion_host_name}"
  location            = var.bastion_pip_location != null ? var.bastion_pip_location : var.location
  resource_group_name = var.bastion_pip_rg_name != null ? var.bastion_pip_rg_name : var.rg_name
  allocation_method   = var.bastion_pip_allocation_method
  sku                 = var.bastion_pip_sku
  tags                = var.tags
}

resource "azurerm_bastion_host" "bastion_host" {
  name                   = var.bastion_host_name
  location               = var.location
  resource_group_name    = var.rg_name
  copy_paste_enabled     = var.copy_paste_enabled
  sku                    = title(var.bastion_sku)
  file_copy_enabled      = var.bastion_sku == "Standard" ? var.file_copy_enabled : null
  ip_connect_enabled     = var.bastion_sku == "Standard" ? var.ip_connect_enabled : null
  scale_units            = var.bastion_sku == "Standard" ? var.scale_units : 2 # 2 is default for Basic sku
  shareable_link_enabled = var.bastion_sku == "Standard" ? var.shareable_link_enabled : null
  tunneling_enabled      = var.bastion_sku == "Standard" ? var.tunneling_enabled : null
  virtual_network_id     = var.bastion_sku == "Developer" ? var.virtual_network_id : null

  dynamic "ip_configuration" {
    for_each = var.bastion_sku != "Developer" && var.create_bastion_subnet || var.external_subnet_id != null ? [1] : []
    content {
      name                 = var.bastion_host_ipconfig_name != null ? var.bastion_host_ipconfig_name : "ipconfig-${var.bastion_host_name}"
      subnet_id            = var.create_bastion_subnet ? azurerm_subnet.bastion_subnet[0].id : var.external_subnet_id
      public_ip_address_id = var.bastion_sku != "Developer" ? azurerm_public_ip.bastion_pip.id : null
    }
  }

  tags = var.tags
}
