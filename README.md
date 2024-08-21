```hcl
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
```
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_bastion_host.bastion_host](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/bastion_host) | resource |
| [azurerm_network_security_group.bastion_nsg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_network_security_rule.bastion_nsg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) | resource |
| [azurerm_public_ip.bastion_pip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_subnet.bastion_subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet_network_security_group_association.bastion_nsg_association](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_azure_bastion_nsg_list"></a> [azure\_bastion\_nsg\_list](#input\_azure\_bastion\_nsg\_list) | The Standard list of NSG rules needed to make a bastion work | `map` | <pre>{<br>  "AllowAzureBastionCommunicationOutbound1": {<br>    "access": "Allow",<br>    "destination_address_prefix": "VirtualNetwork",<br>    "destination_port": "5701",<br>    "direction": "Outbound",<br>    "priority": "180",<br>    "protocol": "Tcp",<br>    "source_address_prefix": "VirtualNetwork",<br>    "source_port": "*"<br>  },<br>  "AllowAzureBastionCommunicationOutbound2": {<br>    "access": "Allow",<br>    "destination_address_prefix": "VirtualNetwork",<br>    "destination_port": "8080",<br>    "direction": "Outbound",<br>    "priority": "185",<br>    "protocol": "Tcp",<br>    "source_address_prefix": "VirtualNetwork",<br>    "source_port": "*"<br>  },<br>  "AllowAzureCloudOutbound2": {<br>    "access": "Allow",<br>    "destination_address_prefix": "AzureCloud",<br>    "destination_port": "443",<br>    "direction": "Outbound",<br>    "priority": "170",<br>    "protocol": "Tcp",<br>    "source_address_prefix": "*",<br>    "source_port": "*"<br>  },<br>  "AllowAzureLoadBalancerInbound": {<br>    "access": "Allow",<br>    "destination_address_prefix": "*",<br>    "destination_port": "443",<br>    "direction": "Inbound",<br>    "priority": "140",<br>    "protocol": "Tcp",<br>    "source_address_prefix": "AzureLoadBalancer",<br>    "source_port": "*"<br>  },<br>  "AllowBastionHostCommunication1": {<br>    "access": "Allow",<br>    "destination_address_prefix": "VirtualNetwork",<br>    "destination_port": "5701",<br>    "direction": "Inbound",<br>    "priority": "150",<br>    "protocol": "Tcp",<br>    "source_address_prefix": "VirtualNetwork",<br>    "source_port": "*"<br>  },<br>  "AllowBastionHostCommunication2": {<br>    "access": "Allow",<br>    "destination_address_prefix": "VirtualNetwork",<br>    "destination_port": "80",<br>    "direction": "Inbound",<br>    "priority": "155",<br>    "protocol": "Tcp",<br>    "source_address_prefix": "VirtualNetwork",<br>    "source_port": "*"<br>  },<br>  "AllowGatewayManagerInbound": {<br>    "access": "Allow",<br>    "destination_address_prefix": "*",<br>    "destination_port": "443",<br>    "direction": "Inbound",<br>    "priority": "130",<br>    "protocol": "Tcp",<br>    "source_address_prefix": "GatewayManager",<br>    "source_port": "*"<br>  },<br>  "AllowGetSessionInformation": {<br>    "access": "Allow",<br>    "destination_address_prefix": "*",<br>    "destination_port": "80",<br>    "direction": "Outbound",<br>    "priority": "190",<br>    "protocol": "Tcp",<br>    "source_address_prefix": "*",<br>    "source_port": "*"<br>  },<br>  "AllowHttpsInbound": {<br>    "access": "Allow",<br>    "destination_address_prefix": "*",<br>    "destination_port": "443",<br>    "direction": "Inbound",<br>    "priority": "120",<br>    "protocol": "Tcp",<br>    "source_address_prefix": "Internet",<br>    "source_port": "*"<br>  },<br>  "AllowSSHRDPOutbound1": {<br>    "access": "Allow",<br>    "destination_address_prefix": "VirtualNetwork",<br>    "destination_port": "22",<br>    "direction": "Outbound",<br>    "priority": "160",<br>    "protocol": "Tcp",<br>    "source_address_prefix": "*",<br>    "source_port": "*"<br>  },<br>  "AllowSSHRDPOutbound2": {<br>    "access": "Allow",<br>    "destination_address_prefix": "VirtualNetwork",<br>    "destination_port": "3389",<br>    "direction": "Outbound",<br>    "priority": "165",<br>    "protocol": "Tcp",<br>    "source_address_prefix": "*",<br>    "source_port": "*"<br>  }<br>}</pre> | no |
| <a name="input_bastion_host_ipconfig_name"></a> [bastion\_host\_ipconfig\_name](#input\_bastion\_host\_ipconfig\_name) | The IP Configuration name for the Azure Bastion | `string` | `null` | no |
| <a name="input_bastion_host_name"></a> [bastion\_host\_name](#input\_bastion\_host\_name) | The name for the Bastion host in the portal | `string` | n/a | yes |
| <a name="input_bastion_nsg_location"></a> [bastion\_nsg\_location](#input\_bastion\_nsg\_location) | The location of the bastion nsg | `string` | `null` | no |
| <a name="input_bastion_nsg_name"></a> [bastion\_nsg\_name](#input\_bastion\_nsg\_name) | The name for the NSG to be created with the AzureBastionSubnet | `string` | `null` | no |
| <a name="input_bastion_nsg_rg_name"></a> [bastion\_nsg\_rg\_name](#input\_bastion\_nsg\_rg\_name) | The resource group name which the NSG should be placed in | `string` | `null` | no |
| <a name="input_bastion_pip_allocation_method"></a> [bastion\_pip\_allocation\_method](#input\_bastion\_pip\_allocation\_method) | The allocation method for the Public IP, default is Static | `string` | `"Static"` | no |
| <a name="input_bastion_pip_location"></a> [bastion\_pip\_location](#input\_bastion\_pip\_location) | The location for the Bastion Public IP, default is UK South | `string` | `null` | no |
| <a name="input_bastion_pip_name"></a> [bastion\_pip\_name](#input\_bastion\_pip\_name) | The name for the Bastion Public IP | `string` | `null` | no |
| <a name="input_bastion_pip_rg_name"></a> [bastion\_pip\_rg\_name](#input\_bastion\_pip\_rg\_name) | The resource group name for Bastion Public IP | `string` | `null` | no |
| <a name="input_bastion_pip_sku"></a> [bastion\_pip\_sku](#input\_bastion\_pip\_sku) | The SKU for the Bastion Public IP, default is Standard | `string` | `"Standard"` | no |
| <a name="input_bastion_sku"></a> [bastion\_sku](#input\_bastion\_sku) | The SKU of the bastion, default is Basic | `string` | `"Basic"` | no |
| <a name="input_bastion_subnet_name"></a> [bastion\_subnet\_name](#input\_bastion\_subnet\_name) | The name of the Azure Bastion Subnet - note, this is a static value and should not be changed | `string` | `"AzureBastionSubnet"` | no |
| <a name="input_bastion_subnet_range"></a> [bastion\_subnet\_range](#input\_bastion\_subnet\_range) | The IP Range for the Bastion Subnet - Note, Minimum is a /27 | `string` | `null` | no |
| <a name="input_bastion_subnet_target_vnet_name"></a> [bastion\_subnet\_target\_vnet\_name](#input\_bastion\_subnet\_target\_vnet\_name) | The name of the VNet the bastion is intended to join | `string` | `null` | no |
| <a name="input_bastion_subnet_target_vnet_rg_name"></a> [bastion\_subnet\_target\_vnet\_rg\_name](#input\_bastion\_subnet\_target\_vnet\_rg\_name) | The name of the resource group that the VNet can be found in | `string` | `null` | no |
| <a name="input_copy_paste_enabled"></a> [copy\_paste\_enabled](#input\_copy\_paste\_enabled) | Whether copy paste is enabled, defaults to true | `bool` | `true` | no |
| <a name="input_create_bastion_nsg"></a> [create\_bastion\_nsg](#input\_create\_bastion\_nsg) | Whether a NSG should be created for the Bastion, defaults to true | `bool` | `true` | no |
| <a name="input_create_bastion_nsg_rules"></a> [create\_bastion\_nsg\_rules](#input\_create\_bastion\_nsg\_rules) | Whether the NSG rules for a bastion should be made, default is true | `bool` | `true` | no |
| <a name="input_create_bastion_subnet"></a> [create\_bastion\_subnet](#input\_create\_bastion\_subnet) | Whether this module should create the bastion subnet for the user, defaults to true | `bool` | `true` | no |
| <a name="input_external_subnet_id"></a> [external\_subnet\_id](#input\_external\_subnet\_id) | The ID of the external subnet if not created by this module. | `string` | `null` | no |
| <a name="input_file_copy_enabled"></a> [file\_copy\_enabled](#input\_file\_copy\_enabled) | Whether file copy is enabled | `bool` | `null` | no |
| <a name="input_ip_connect_enabled"></a> [ip\_connect\_enabled](#input\_ip\_connect\_enabled) | Whether the IP connect feature is enabled | `bool` | `null` | no |
| <a name="input_location"></a> [location](#input\_location) | The location for the bastion host, default is UK South | `string` | n/a | yes |
| <a name="input_rg_name"></a> [rg\_name](#input\_rg\_name) | The resource group name for the Bastion resource | `string` | n/a | yes |
| <a name="input_scale_units"></a> [scale\_units](#input\_scale\_units) | The number of scale units, default is 2 | `number` | `2` | no |
| <a name="input_shareable_link_enabled"></a> [shareable\_link\_enabled](#input\_shareable\_link\_enabled) | Whether the shareable link is enabled | `bool` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | The default tags to be assigned | `map(string)` | n/a | yes |
| <a name="input_tunneling_enabled"></a> [tunneling\_enabled](#input\_tunneling\_enabled) | Whether the tunneling feature is enable | `bool` | `null` | no |
| <a name="input_virtual_network_id"></a> [virtual\_network\_id](#input\_virtual\_network\_id) | The ID of the virtual network that the bastion should be attached to when in Developer SKU | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bastion_dns_name"></a> [bastion\_dns\_name](#output\_bastion\_dns\_name) | The DNS name of the Azure Bastion |
| <a name="output_bastion_hostname"></a> [bastion\_hostname](#output\_bastion\_hostname) | The host name of the bastion |
| <a name="output_bastion_ip_configuration"></a> [bastion\_ip\_configuration](#output\_bastion\_ip\_configuration) | The bastion host ip\_configuration block |
| <a name="output_bastion_nsg_id"></a> [bastion\_nsg\_id](#output\_bastion\_nsg\_id) | The host name of the bastion |
| <a name="output_bastion_nsg_name"></a> [bastion\_nsg\_name](#output\_bastion\_nsg\_name) | The name of the bastion nsg |
| <a name="output_bastion_subnet_id"></a> [bastion\_subnet\_id](#output\_bastion\_subnet\_id) | The subnet ID associated with the bastion host's IP configuration |
| <a name="output_bastion_subnet_ip_range"></a> [bastion\_subnet\_ip\_range](#output\_bastion\_subnet\_ip\_range) | Bastion subnet IP range |
