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