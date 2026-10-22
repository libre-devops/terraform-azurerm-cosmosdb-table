locals {
  account             = provider::azurerm::parse_resource_id(var.cosmosdb_account_id)
  account_name        = local.account.resource_name
  resource_group_name = local.account.resource_group_name
}
