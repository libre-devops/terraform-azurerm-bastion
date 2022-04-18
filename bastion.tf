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