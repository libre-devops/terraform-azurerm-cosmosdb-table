locals {
  location     = lookup(var.regions, var.loc, "uksouth")
  rg_name      = "rg-${var.short}-${var.loc}-${terraform.workspace}-001"
  account_name = "cosmos-${var.short}-${var.loc}-${terraform.workspace}-001"
}

module "tags" {
  source  = "libre-devops/tags/azurerm"
  version = "~> 4.0"

  cost_centre     = "1888/67"
  owner           = "platform@example.com"
  deployed_branch = var.deployed_branch
  deployed_repo   = var.deployed_repo
}

module "rg" {
  source  = "libre-devops/rg/azurerm"
  version = "~> 4.0"

  resource_groups = [{ name = local.rg_name, location = local.location, tags = module.tags.tags }]
}

# A serverless API for Table account to hold the table (Entra ID only, from the account module).
module "cosmosdb" {
  source = "git::https://github.com/libre-devops/terraform-azurerm-cosmosdb-account.git?ref=1.0.0"

  resource_group_id = module.rg.ids[local.rg_name]
  location          = local.location
  tags              = module.tags.tags

  cosmosdb_accounts = {
    (local.account_name) = { capabilities = ["EnableTable", "EnableServerless"] }
  }
}

# Minimal call: one table, with no throughput, as the account is serverless.
module "tables" {
  source = "../../"

  cosmosdb_account_id = module.cosmosdb.ids[local.account_name]

  tables = {
    devices = {}
  }
}
