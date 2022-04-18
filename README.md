# terraform-azurerm-bastion
A module used to create a bastion server inside a virtual network, with an NSG and all the rules needed.


```hcl
module "bastion" {
  source = "registry.terraform.io/libre-devops/nsg/azurerm"


  vnet_rg_name = module.network.vnet_rg_name
  vnet_name    = module.network.vnet_name

  bas_subnet_iprange = "10.0.0.4.0/28"

  bas_nsg_name     = "nsg-bas-${var.short}-${var.loc}-${terraform.workspace}-01"
  bas_nsg_location = module.rg.rg_location
  bas_nsg_rg_name  = module.rg.rg_name

  bas_pip_name              = "pip-bas-${var.short}-${var.loc}-${terraform.workspace}-01"
  bas_pip_location          = module.rg.rg_location
  bas_pip_rg_name           = module.rg.rg_name
  bas_pip_allocation_method = "Static"
  bas_pip_sku               = "Standard"

  bas_host_name          = "bas-${var.short}-${var.loc}-${terraform.workspace}-01"
  bas_host_location      = module.rg.rg_location
  bas_host_rg_name       = module.rg.rg_name
  bas_host_ipconfig_name = "bas-${var.short}-${var.loc}-${terraform.workspace}-01-ipconfig"

  tags = module.rg.rg_tags
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
| [azurerm_bastion_host.bas_host](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/bastion_host) | resource |
| [azurerm_network_security_group.bas_nsg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_network_security_rule.bas_nsg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) | resource |
| [azurerm_public_ip.bas_pip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_subnet.bas_subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet_network_security_group_association.bas_nsg_association](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_azure_bastion_nsg_list"></a> [azure\_bastion\_nsg\_list](#input\_azure\_bastion\_nsg\_list) | The Standard list of NSG rules needed to make a bastion work | `map` | <pre>{<br>  "AllowAzureBastionCommunicationOutbound1": {<br>    "access": "Allow",<br>    "destination_address_prefix": "VirtualNetwork",<br>    "destination_port": "5701",<br>    "direction": "Outbound",<br>    "priority": "180",<br>    "protocol": "Tcp",<br>    "source_address_prefix": "VirtualNetwork",<br>    "source_port": "*"<br>  },<br>  "AllowAzureBastionCommunicationOutbound2": {<br>    "access": "Allow",<br>    "destination_address_prefix": "VirtualNetwork",<br>    "destination_port": "8080",<br>    "direction": "Outbound",<br>    "priority": "185",<br>    "protocol": "Tcp",<br>    "source_address_prefix": "VirtualNetwork",<br>    "source_port": "*"<br>  },<br>  "AllowAzureCloudOutbound2": {<br>    "access": "Allow",<br>    "destination_address_prefix": "AzureCloud",<br>    "destination_port": "443",<br>    "direction": "Outbound",<br>    "priority": "170",<br>    "protocol": "Tcp",<br>    "source_address_prefix": "*",<br>    "source_port": "*"<br>  },<br>  "AllowAzureLoadBalancerInbound": {<br>    "access": "Allow",<br>    "destination_address_prefix": "*",<br>    "destination_port": "443",<br>    "direction": "Inbound",<br>    "priority": "140",<br>    "protocol": "Tcp",<br>    "source_address_prefix": "AzureLoadBalancer",<br>    "source_port": "*"<br>  },<br>  "AllowBastionHostCommunication1": {<br>    "access": "Allow",<br>    "destination_address_prefix": "VirtualNetwork",<br>    "destination_port": "5701",<br>    "direction": "Inbound",<br>    "priority": "150",<br>    "protocol": "Tcp",<br>    "source_address_prefix": "VirtualNetwork",<br>    "source_port": "*"<br>  },<br>  "AllowBastionHostCommunication2": {<br>    "access": "Allow",<br>    "destination_address_prefix": "VirtualNetwork",<br>    "destination_port": "80",<br>    "direction": "Inbound",<br>    "priority": "155",<br>    "protocol": "Tcp",<br>    "source_address_prefix": "VirtualNetwork",<br>    "source_port": "*"<br>  },<br>  "AllowGatewayManagerInbound": {<br>    "access": "Allow",<br>    "destination_address_prefix": "*",<br>    "destination_port": "443",<br>    "direction": "Inbound",<br>    "priority": "130",<br>    "protocol": "Tcp",<br>    "source_address_prefix": "GatewayManager",<br>    "source_port": "*"<br>  },<br>  "AllowGetSessionInformation": {<br>    "access": "Allow",<br>    "destination_address_prefix": "*",<br>    "destination_port": "80",<br>    "direction": "Outbound",<br>    "priority": "190",<br>    "protocol": "Tcp",<br>    "source_address_prefix": "*",<br>    "source_port": "*"<br>  },<br>  "AllowHttpsInbound": {<br>    "access": "Allow",<br>    "destination_address_prefix": "*",<br>    "destination_port": "443",<br>    "direction": "Inbound",<br>    "priority": "120",<br>    "protocol": "Tcp",<br>    "source_address_prefix": "Internet",<br>    "source_port": "*"<br>  },<br>  "AllowSSHRDPOutbound1": {<br>    "access": "Allow",<br>    "destination_address_prefix": "VirtualNetwork",<br>    "destination_port": "22",<br>    "direction": "Outbound",<br>    "priority": "160",<br>    "protocol": "Tcp",<br>    "source_address_prefix": "*",<br>    "source_port": "*"<br>  },<br>  "AllowSSHRDPOutbound2": {<br>    "access": "Allow",<br>    "destination_address_prefix": "VirtualNetwork",<br>    "destination_port": "3389",<br>    "direction": "Outbound",<br>    "priority": "165",<br>    "protocol": "Tcp",<br>    "source_address_prefix": "*",<br>    "source_port": "*"<br>  }<br>}</pre> | no |
| <a name="input_bas_host_ipconfig_name"></a> [bas\_host\_ipconfig\_name](#input\_bas\_host\_ipconfig\_name) | The IP Configuration name for the Azure Bastion | `string` | n/a | yes |
| <a name="input_bas_host_location"></a> [bas\_host\_location](#input\_bas\_host\_location) | The location for the bastion host, default is UK South | `string` | n/a | yes |
| <a name="input_bas_host_name"></a> [bas\_host\_name](#input\_bas\_host\_name) | The name for the Bastion host in the portal | `string` | n/a | yes |
| <a name="input_bas_host_rg_name"></a> [bas\_host\_rg\_name](#input\_bas\_host\_rg\_name) | The resource group name for the Bastion resource | `string` | n/a | yes |
| <a name="input_bas_nsg_location"></a> [bas\_nsg\_location](#input\_bas\_nsg\_location) | The location of the bastion nsg | `string` | n/a | yes |
| <a name="input_bas_nsg_name"></a> [bas\_nsg\_name](#input\_bas\_nsg\_name) | The name for the NSG to be created with the AzureBastionSubnet | `string` | n/a | yes |
| <a name="input_bas_nsg_rg_name"></a> [bas\_nsg\_rg\_name](#input\_bas\_nsg\_rg\_name) | The resource group name which the NSG should be placed in | `any` | n/a | yes |
| <a name="input_bas_pip_allocation_method"></a> [bas\_pip\_allocation\_method](#input\_bas\_pip\_allocation\_method) | The allocation method for the Public IP, default is Static | `string` | `"Static"` | no |
| <a name="input_bas_pip_location"></a> [bas\_pip\_location](#input\_bas\_pip\_location) | The location for the Bastion Public IP, default is UK South | `string` | n/a | yes |
| <a name="input_bas_pip_name"></a> [bas\_pip\_name](#input\_bas\_pip\_name) | The name for the Bastion Public IP | `string` | n/a | yes |
| <a name="input_bas_pip_rg_name"></a> [bas\_pip\_rg\_name](#input\_bas\_pip\_rg\_name) | The resource group name for Bastion Public IP | `string` | n/a | yes |
| <a name="input_bas_pip_sku"></a> [bas\_pip\_sku](#input\_bas\_pip\_sku) | The SKU for the Bastion Public IP, default is Standard | `string` | `"Standard"` | no |
| <a name="input_bas_subnet_iprange"></a> [bas\_subnet\_iprange](#input\_bas\_subnet\_iprange) | The IP Range for the Bastion Subnet - Note, Minimum is a /28 | `string` | n/a | yes |
| <a name="input_bas_subnet_name"></a> [bas\_subnet\_name](#input\_bas\_subnet\_name) | The name of the Azure Bastion Subnet - note, this is a static value and should not be changed | `string` | `"AzureBastionSubnet"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | The default tags to be assigned | `map(any)` | n/a | yes |
| <a name="input_vnet_name"></a> [vnet\_name](#input\_vnet\_name) | The name of the VNet the bastion is intended to join | `string` | n/a | yes |
| <a name="input_vnet_rg_name"></a> [vnet\_rg\_name](#input\_vnet\_rg\_name) | The name of the resource group that the VNet can be found int | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bas_hostname"></a> [bas\_hostname](#output\_bas\_hostname) | The host name of the bastion |
| <a name="output_bas_nsg_id"></a> [bas\_nsg\_id](#output\_bas\_nsg\_id) | The host name of the bastion |
| <a name="output_bas_nsg_name"></a> [bas\_nsg\_name](#output\_bas\_nsg\_name) | The name of the bastion nsg |
| <a name="output_bas_subnet_id"></a> [bas\_subnet\_id](#output\_bas\_subnet\_id) | The host name of the bastion |
| <a name="output_bas_subnet_ip_range"></a> [bas\_subnet\_ip\_range](#output\_bas\_subnet\_ip\_range) | Bastion subnet IP range |
| <a name="output_bas_subnet_name"></a> [bas\_subnet\_name](#output\_bas\_subnet\_name) | The subnet name of the Azure Bastion subnet |
