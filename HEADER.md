<!--
  Keep the title and badges OUTSIDE the centered <div>: the Terraform Registry's markdown renderer
  does not parse markdown inside an HTML block, so a # heading or [![badge]] in the div renders as
  literal text on the registry. Only the logo (HTML) goes in the div.
-->
<div align="center">
  <a href="https://libredevops.org">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://libredevops.org/assets/libre-devops-white.png">
      <img alt="Libre DevOps" src="https://libredevops.org/assets/libre-devops-black.png" width="300">
    </picture>
  </a>
</div>

# Terraform Azure Bastion

Bastion hosts that default to the free Developer SKU (one attribute and you can connect), scaling to
Basic, Standard, and Premium when you need them.

[![CI](https://github.com/libre-devops/terraform-azurerm-bastion/actions/workflows/ci.yml/badge.svg)](https://github.com/libre-devops/terraform-azurerm-bastion/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/libre-devops/terraform-azurerm-bastion?sort=semver&label=release)](https://github.com/libre-devops/terraform-azurerm-bastion/releases/latest)
[![Terraform Registry](https://img.shields.io/badge/registry-libre--devops-7B42BC?logo=terraform&logoColor=white)](https://registry.terraform.io/namespaces/libre-devops)
[![License](https://img.shields.io/github/license/libre-devops/terraform-azurerm-bastion)](./LICENSE)

---

## Overview

Bastion hosts keyed by name. The default SKU is **Developer**: the lightweight shared-pool offering
that just attaches to a virtual network (set `virtual_network_id` and you are done), needs no
AzureBastionSubnet, no public IP, no scale units, and costs nothing, which makes the module the
fastest way to get secure VM access going.

Scaling up is per host: `sku = "Basic" | "Standard" | "Premium"` with an `ip_configuration` (the
dedicated AzureBastionSubnet at /26 or larger, plus a `public_ip_address_id` that comes from the
`public-ip` module: this module never creates public IPs, it only accepts them as inputs). Standard
adds `scale_units`, zones, and the feature toggles (file copy, IP connect, Kerberos, shareable links,
tunneling); Premium adds session recording and may omit the public IP for a private-only bastion.
Every SKU/feature mismatch fails the plan with a specific message rather than at the API.

## Usage

```hcl
module "bastion" {
  source  = "libre-devops/bastion/azurerm"
  version = "~> 4.0"

  resource_group_id = module.rg.ids["rg-ldo-uks-prd-001"]
  location          = "uksouth"
  tags              = module.tags.tags

  bastion_hosts = {
    # The Developer default: one attribute.
    "bas-ldo-uks-prd-001" = {
      virtual_network_id = module.network.vnet_id
    }

    # Scaled up when needed.
    "bas-ldo-hub-uks-prd-001" = {
      sku = "Standard"
      ip_configuration = {
        subnet_id            = module.network.subnet_ids["AzureBastionSubnet"]
        public_ip_address_id = module.public_ip.public_ip_ids["pip-bas-ldo-uks-prd-001"]
      }
      tunneling_enabled = true
    }
  }
}
```

## Examples

- [`examples/minimal`](./examples/minimal) - a Developer bastion attached to a vnet: the one-attribute
  path.
- [`examples/complete`](./examples/complete) - a Developer host alongside a Standard host with scale
  units, zones, the feature toggles, and the public IP passed in from the public-ip module (one
  bastion per vnet, so each gets its own). Premium session recording is exercised in the mocked
  tests; a Premium host adds nothing to the example but cost.

## Developing

Local work needs **PowerShell 7+** and **[`just`](https://github.com/casey/just)**, because the recipes
wrap the [LibreDevOpsHelpers](https://www.powershellgallery.com/packages/LibreDevOpsHelpers)
PowerShell module (the same engine the `libre-devops/terraform-azure` action runs in CI). Install
just with `brew install just`, or `uv tool add rust-just` then `uv run just <recipe>`.

Run `just` to list recipes: `just update-ldo-pwsh` (install or force-update LibreDevOpsHelpers from
PSGallery), `just validate`, `just scan` (Trivy only), `just pwsh-analyze` (PSScriptAnalyzer only),
`just plan`, `just apply`, `just destroy`, `just e2e`, `just test`, and `just docs` (the
plan/apply/destroy recipes mirror the action, including the storage firewall dance; `just e2e`
applies an example then always destroys it, defaulting to `minimal`, so nothing is left running).
Releasing is also `just`:
`just increment-release [patch|minor|major]` bumps, tags, and publishes a GitHub release, and the
Terraform Registry picks up the tag.

## Security scan exceptions

This module is scanned with [Trivy](https://github.com/aquasecurity/trivy); HIGH and CRITICAL
findings fail the build. Any waiver is a deliberate, reviewed decision, never a way to quiet a
finding that should be fixed. Waivers live in [`.trivyignore.yaml`](./.trivyignore.yaml) (the
machine-applied source of truth, passed to Trivy with `--ignorefile`) and are mirrored in a table
here so the reason is auditable.

There are currently **no exceptions**: the module and its examples scan clean. A bastion exists to
REMOVE public management-port exposure, so there is nothing to waive.

To add an exception: add an entry to `.trivyignore.yaml` (`id`, optional `paths` to scope it, and a
`statement` recording why), then add a matching row here recording the reason. Both the file and
the table are reviewed in the pull request.

## Reference

The Requirements, Providers, Inputs, Outputs, and Resources below are generated by `terraform-docs`.
