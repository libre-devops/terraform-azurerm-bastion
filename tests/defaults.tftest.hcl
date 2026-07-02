# Plan-time tests for the module. The azurerm provider is mocked, so no credentials, no features
# block, and no cloud calls are needed:
#   terraform init -backend=false && terraform test

mock_provider "azurerm" {}

variables {
  resource_group_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ldo-uks-tst-001"
  location          = "uksouth"
  tags              = { Environment = "tst" }
}

# The Developer default: one attribute (the vnet) and you have a bastion.
run "developer_default" {
  command = apply

  variables {
    bastion_hosts = {
      "bas-dev" = {
        virtual_network_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ldo-uks-tst-001/providers/Microsoft.Network/virtualNetworks/vnet-ldo-uks-tst-001"
      }
    }
  }

  assert {
    condition     = azurerm_bastion_host.this["bas-dev"].sku == "Developer"
    error_message = "The SKU should default to Developer."
  }

  assert {
    condition     = length(azurerm_bastion_host.this["bas-dev"].ip_configuration) == 0
    error_message = "A Developer bastion should carry no ip_configuration."
  }

  assert {
    condition     = azurerm_bastion_host.this["bas-dev"].copy_paste_enabled == true
    error_message = "copy_paste should default on."
  }
}

# A Standard host with features, scale units, zones, and the public IP passed as an input.
run "standard_full" {
  command = apply

  variables {
    bastion_hosts = {
      "bas-std" = {
        sku = "Standard"
        ip_configuration = {
          subnet_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ldo-uks-tst-001/providers/Microsoft.Network/virtualNetworks/vnet-t/subnets/AzureBastionSubnet"
          public_ip_address_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ldo-uks-tst-001/providers/Microsoft.Network/publicIPAddresses/pip-bas"
        }
        scale_units        = 4
        zones              = ["1", "2"]
        file_copy_enabled  = true
        tunneling_enabled  = true
        ip_connect_enabled = true
      }
    }
  }

  assert {
    condition     = azurerm_bastion_host.this["bas-std"].scale_units == 4
    error_message = "scale_units should pass through on Standard."
  }

  assert {
    condition     = azurerm_bastion_host.this["bas-std"].file_copy_enabled == true && azurerm_bastion_host.this["bas-std"].tunneling_enabled == true
    error_message = "Standard features should pass through."
  }
}

# Premium without a public IP is the private-only shape and is allowed.
run "premium_private_only" {
  command = apply

  variables {
    bastion_hosts = {
      "bas-prem" = {
        sku = "Premium"
        ip_configuration = {
          subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ldo-uks-tst-001/providers/Microsoft.Network/virtualNetworks/vnet-t/subnets/AzureBastionSubnet"
        }
        session_recording_enabled = true
      }
    }
  }

  assert {
    condition     = azurerm_bastion_host.this["bas-prem"].session_recording_enabled == true
    error_message = "session_recording should pass through on Premium."
  }
}

# A Developer host without a vnet fails the plan.
run "rejects_developer_without_vnet" {
  command = plan

  variables {
    bastion_hosts = {
      "bas-bad" = {}
    }
  }

  expect_failures = [azurerm_bastion_host.this]
}

# A Basic host without a public IP fails the plan (only Premium supports private-only).
run "rejects_basic_without_public_ip" {
  command = plan

  variables {
    bastion_hosts = {
      "bas-basic" = {
        sku = "Basic"
        ip_configuration = {
          subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ldo-uks-tst-001/providers/Microsoft.Network/virtualNetworks/vnet-t/subnets/AzureBastionSubnet"
        }
      }
    }
  }

  expect_failures = [azurerm_bastion_host.this]
}

# Standard-tier features on a Basic host fail the plan.
run "rejects_features_on_basic" {
  command = plan

  variables {
    bastion_hosts = {
      "bas-basic" = {
        sku = "Basic"
        ip_configuration = {
          subnet_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ldo-uks-tst-001/providers/Microsoft.Network/virtualNetworks/vnet-t/subnets/AzureBastionSubnet"
          public_ip_address_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ldo-uks-tst-001/providers/Microsoft.Network/publicIPAddresses/pip-bas"
        }
        tunneling_enabled = true
      }
    }
  }

  expect_failures = [azurerm_bastion_host.this]
}

# session recording outside Premium fails the plan.
run "rejects_session_recording_on_standard" {
  command = plan

  variables {
    bastion_hosts = {
      "bas-std" = {
        sku = "Standard"
        ip_configuration = {
          subnet_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ldo-uks-tst-001/providers/Microsoft.Network/virtualNetworks/vnet-t/subnets/AzureBastionSubnet"
          public_ip_address_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ldo-uks-tst-001/providers/Microsoft.Network/publicIPAddresses/pip-bas"
        }
        session_recording_enabled = true
      }
    }
  }

  expect_failures = [azurerm_bastion_host.this]
}

# virtual_network_id on a paid SKU trips the advisory check.
run "flags_vnet_on_paid_sku" {
  command = plan

  variables {
    bastion_hosts = {
      "bas-std" = {
        sku                = "Standard"
        virtual_network_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-t/providers/Microsoft.Network/virtualNetworks/vnet-t"
        ip_configuration = {
          subnet_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ldo-uks-tst-001/providers/Microsoft.Network/virtualNetworks/vnet-t/subnets/AzureBastionSubnet"
          public_ip_address_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ldo-uks-tst-001/providers/Microsoft.Network/publicIPAddresses/pip-bas"
        }
      }
    }
  }

  expect_failures = [check.vnet_id_only_matters_for_developer]
}
