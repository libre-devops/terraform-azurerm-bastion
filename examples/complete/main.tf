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
