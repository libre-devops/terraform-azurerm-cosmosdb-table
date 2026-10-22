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

A provisioned API for Table account from the cosmosdb-account module, with the deployer holding
the built-in data reader role, and two tables: one with manual throughput and one with an autoscale
ceiling. The environment comes from the Terraform workspace, not a variable. Run it with
`just e2e complete`, which applies the stack then always destroys it.

[![Terraform Registry](https://img.shields.io/badge/registry-libre--devops-7B42BC?logo=terraform&logoColor=white)](https://registry.terraform.io/namespaces/libre-devops)

<!-- BEGIN_TF_DOCS -->
## Example configuration

```hcl
locals {
  location     = lookup(var.regions, var.loc, "uksouth")
  rg_name      = "rg-${var.short}-${var.loc}-${terraform.workspace}-002"
  account_name = "cosmos-${var.short}-${var.loc}-${terraform.workspace}-002"
}

data "azurerm_client_config" "current" {}

module "tags" {
  source  = "libre-devops/tags/azurerm"
  version = "~> 4.0"

  environment     = "prd"
  cost_centre     = "1888/67"
  owner           = "platform@example.com"
  deployed_branch = var.deployed_branch
  deployed_repo   = var.deployed_repo
  additional_tags = { Application = "terraform-azurerm-cosmosdb-table" }
}

module "rg" {
  source  = "libre-devops/rg/azurerm"
  version = "~> 4.0"

  resource_groups = [{ name = local.rg_name, location = local.location, tags = module.tags.tags }]
}

# A provisioned API for Table account, so each table can carry its own throughput, with the
# deployer holding the built-in data reader role on the account.
module "cosmosdb" {
  source = "git::https://github.com/libre-devops/terraform-azurerm-cosmosdb-account.git?ref=1.0.0"

  resource_group_id = module.rg.ids[local.rg_name]
  location          = local.location
  tags              = module.tags.tags

  cosmosdb_accounts = {
    (local.account_name) = {
      capabilities = ["EnableTable"]

      table_role_assignments = {
        deployer = {
          principal_id         = data.azurerm_client_config.current.object_id
          role_definition_name = "Cosmos DB Built-in Data Reader"
        }
      }
    }
  }
}

# Complete call: a table with manual throughput and one with an autoscale ceiling.
module "tables" {
  source = "../../"

  cosmosdb_account_id = module.cosmosdb.ids[local.account_name]

  tables = {
    devices = { throughput = 400 }
    events  = { autoscale_max_throughput = 1000 }
  }
}
```

## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11.0, < 2.0.0 |
| <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) | >= 2.13.0, < 3.0.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 4.0.0, < 5.0.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 4.0.0, < 5.0.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_cosmosdb"></a> [cosmosdb](#module\_cosmosdb) | git::https://github.com/libre-devops/terraform-azurerm-cosmosdb-account.git | 1.0.0 |
| <a name="module_rg"></a> [rg](#module\_rg) | libre-devops/rg/azurerm | ~> 4.0 |
| <a name="module_tables"></a> [tables](#module\_tables) | ../../ | n/a |
| <a name="module_tags"></a> [tags](#module\_tags) | libre-devops/tags/azurerm | ~> 4.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_deployed_branch"></a> [deployed\_branch](#input\_deployed\_branch) | Git branch the deployment came from. Auto-filled in CI from TF\_VAR\_deployed\_branch. | `string` | `""` | no |
| <a name="input_deployed_repo"></a> [deployed\_repo](#input\_deployed\_repo) | Repository URL the deployment came from. Auto-filled in CI from TF\_VAR\_deployed\_repo. | `string` | `""` | no |
| <a name="input_loc"></a> [loc](#input\_loc) | Outfix: short Azure region code used in resource names (for example uks). | `string` | `"uks"` | no |
| <a name="input_regions"></a> [regions](#input\_regions) | Map of short region codes to Azure region slugs. | `map(string)` | <pre>{<br/>  "eus": "eastus",<br/>  "euw": "westeurope",<br/>  "uks": "uksouth",<br/>  "ukw": "ukwest"<br/>}</pre> | no |
| <a name="input_short"></a> [short](#input\_short) | Infix: short product code used in resource names. | `string` | `"ldo"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of table name to id. |
| <a name="output_names"></a> [names](#output\_names) | The table names. |
<!-- END_TF_DOCS -->
