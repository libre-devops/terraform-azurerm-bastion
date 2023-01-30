resource "azurerm_bastion_host" "bas_host" {
  name                   = var.bas_host_name
  location               = var.bas_host_location
  resource_group_name    = var.bas_host_rg_name
  copy_paste_enabled     = var.copy_pasted_enabled
  sku                    = title(var.sku)
  file_copy_enabled      = var.sku == "Standard" ? var.file_copy_enabled : null
  ip_connect_enabled     = var.sku == "Standard" ? var.ip_connect_true : null
  scale_units            = var.sku == "Standard" ? var.scale_units : 2 # 2 is default for Basic sku
  shareable_link_enabled = var.sku == "Standard" ? var.shareable_link_enabled : null
  tunneling_enabled      = var.sku == "Standard" ? var.tunneling_enable : null

  ip_configuration {
    name                 = var.bas_host_ipconfig_name
    subnet_id            = azurerm_subnet.bas_subnet.id
    public_ip_address_id = azurerm_public_ip.bas_pip.id
  }

  tags = var.tags
}