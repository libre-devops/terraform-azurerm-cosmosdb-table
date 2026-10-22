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
