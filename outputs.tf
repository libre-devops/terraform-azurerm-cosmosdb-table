output "account_name" {
  description = "The account name, parsed from cosmosdb_account_id."
  value       = local.account_name
}

output "ids" {
  description = "Map of table name to its resource id."
  value       = { for k, t in azurerm_cosmosdb_table.this : k => t.id }
}

output "ids_zipmap" {
  description = "Map of table name to a { name, id } object, for passing where both are needed together."
  value       = { for k, t in azurerm_cosmosdb_table.this : k => { name = t.name, id = t.id } }
}

output "names" {
  description = "The table names."
  value       = keys(azurerm_cosmosdb_table.this)
}

output "resource_group_name" {
  description = "The account's resource group, parsed from cosmosdb_account_id."
  value       = local.resource_group_name
}
