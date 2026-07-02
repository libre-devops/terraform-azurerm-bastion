<!--
  Header for the complete example README. Edit this file, then run `just docs`
  (or ./Sort-LdoTerraform.ps1 -IncludeExamples) to regenerate the section between the markers.
  The example's main.tf is embedded into the README automatically (see .terraform-docs.yml).
-->
<div align="center">
  <a href="https://libredevops.org">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://libredevops.org/assets/libre-devops-white.png">
      <img alt="Libre DevOps" src="https://libredevops.org/assets/libre-devops-black.png" width="200">
    </picture>
  </a>
</div>

# Complete example

The full surface of the module: the free Developer default alongside a Standard host exercising the
paid surface (a dedicated AzureBastionSubnet, scale units, zones, the feature toggles, and the public
IP passed in from the public-ip module, which is where public IPs live). Azure allows one bastion per
virtual network, so each host gets its own vnet. Premium session recording is exercised in the mocked
tests; a Premium host adds nothing to the example but cost. Run it with `just e2e complete`, which
applies the stack then always destroys it.

[![Terraform Registry](https://img.shields.io/badge/registry-libre--devops-7B42BC?logo=terraform&logoColor=white)](https://registry.terraform.io/namespaces/libre-devops)

<!-- BEGIN_TF_DOCS -->
## Example configuration

```hcl
locals {
  location = lookup(var.regions, var.loc, "uksouth")
  rg_name  = "rg-${var.short}-${var.loc}-${terraform.workspace}-002"

  # Azure allows one bastion per virtual network, so the two hosts get a vnet each.
  vnet_dev_name = "vnet-${var.short}-dev-${var.loc}-${terraform.workspace}-002"
  vnet_std_name = "vnet-${var.short}-std-${var.loc}-${terraform.workspace}-002"
  pip_name      = "pip-bas-${var.short}-${var.loc}-${terraform.workspace}-002"
}

module "tags" {
  source  = "libre-devops/tags/azurerm"
  version = "~> 4.0"

  cost_centre     = "1888/67"
  owner           = "platform@example.com"
  deployed_branch = var.deployed_branch
  deployed_repo   = var.deployed_repo
  additional_tags = { Application = "terraform-azurerm-bastion" }
}

module "rg" {
  source  = "libre-devops/rg/azurerm"
  version = "~> 4.0"

  resource_groups = [{ name = local.rg_name, location = local.location, tags = module.tags.tags }]
}

module "network_developer" {
  source  = "libre-devops/network/azurerm"
  version = "~> 4.0"

  resource_group_id = module.rg.ids[local.rg_name]
  location          = local.location
  tags              = module.tags.tags

  vnet_name     = local.vnet_dev_name
  address_space = ["10.10.0.0/16"]
  subnets = {
    "snet-app-${local.vnet_dev_name}" = { address_prefixes = ["10.10.1.0/24"] }
  }
}

# The Standard host needs the dedicated AzureBastionSubnet (/26 or larger).
module "network_standard" {
  source  = "libre-devops/network/azurerm"
  version = "~> 4.0"

  resource_group_id = module.rg.ids[local.rg_name]
  location          = local.location
  tags              = module.tags.tags

  vnet_name     = local.vnet_std_name
  address_space = ["10.20.0.0/16"]
  subnets = {
    "AzureBastionSubnet" = { address_prefixes = ["10.20.0.0/26"] }
  }
}

# The public IP comes from the public-ip module: this module never creates public IPs, it only
# accepts them as inputs.
module "public_ip" {
  source  = "libre-devops/public-ip/azurerm"
  version = "~> 4.0"

  resource_group_id = module.rg.ids[local.rg_name]
  location          = local.location
  tags              = module.tags.tags

  public_ips = {
    (local.pip_name) = {}
  }
}

# Complete call: the free Developer default alongside a Standard host exercising the paid surface
# (scale units, zones, features, and the public IP as an input). Premium session recording is
# exercised in the mocked tests; a Premium host adds nothing else to the example but cost.
module "bastion" {
  source = "../../"

  resource_group_id = module.rg.ids[local.rg_name]
  location          = local.location
  tags              = module.tags.tags

  bastion_hosts = {
    "bas-${var.short}-dev-${var.loc}-${terraform.workspace}-002" = {
      virtual_network_id = module.network_developer.vnet_id
      tags               = { Component = "developer" }
    }

    "bas-${var.short}-std-${var.loc}-${terraform.workspace}-002" = {
      sku = "Standard"
      ip_configuration = {
        subnet_id            = module.network_standard.subnet_ids["AzureBastionSubnet"]
        public_ip_address_id = module.public_ip.public_ip_ids[local.pip_name]
      }
      scale_units        = 2
      zones              = ["1", "2", "3"]
      file_copy_enabled  = true
      tunneling_enabled  = true
      ip_connect_enabled = true
      kerberos_enabled   = false
    }
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0, < 2.0.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 4.0.0, < 5.0.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_bastion"></a> [bastion](#module\_bastion) | ../../ | n/a |
| <a name="module_network_developer"></a> [network\_developer](#module\_network\_developer) | libre-devops/network/azurerm | ~> 4.0 |
| <a name="module_network_standard"></a> [network\_standard](#module\_network\_standard) | libre-devops/network/azurerm | ~> 4.0 |
| <a name="module_public_ip"></a> [public\_ip](#module\_public\_ip) | libre-devops/public-ip/azurerm | ~> 4.0 |
| <a name="module_rg"></a> [rg](#module\_rg) | libre-devops/rg/azurerm | ~> 4.0 |
| <a name="module_tags"></a> [tags](#module\_tags) | libre-devops/tags/azurerm | ~> 4.0 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_deployed_branch"></a> [deployed\_branch](#input\_deployed\_branch) | Git branch the deployment came from. Auto-filled in CI from TF\_VAR\_deployed\_branch. | `string` | `""` | no |
| <a name="input_deployed_repo"></a> [deployed\_repo](#input\_deployed\_repo) | Repository URL the deployment came from. Auto-filled in CI from TF\_VAR\_deployed\_repo. | `string` | `""` | no |
| <a name="input_loc"></a> [loc](#input\_loc) | Outfix: short Azure region code used in resource names (for example uks). | `string` | `"uks"` | no |
| <a name="input_regions"></a> [regions](#input\_regions) | Map of short region codes to Azure region slugs. | `map(string)` | <pre>{<br/>  "eus": "eastus",<br/>  "euw": "westeurope",<br/>  "uks": "uksouth",<br/>  "ukw": "ukwest"<br/>}</pre> | no |
| <a name="input_short"></a> [short](#input\_short) | Infix: short product code used in resource names. | `string` | `"ldo"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_dns_names"></a> [dns\_names](#output\_dns\_names) | Map of bastion name to DNS name. |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of bastion name to resource id. |
| <a name="output_ids_zipmap"></a> [ids\_zipmap](#output\_ids\_zipmap) | Map of bastion name to { name, id }. |
| <a name="output_private_only"></a> [private\_only](#output\_private\_only) | Map of bastion name to private-only status. |
<!-- END_TF_DOCS -->
