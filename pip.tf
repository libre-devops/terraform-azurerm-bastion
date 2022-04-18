resource "azurerm_public_ip" "bas_pip" {
  name                = var.bas_pip_name
  location            = var.bas_pip_location
  resource_group_name = var.bas_pip_rg_name
  allocation_method   = var.bas_pip_allocation_method
  sku                 = var.bas_pip_sku
  tags                = var.tags
}