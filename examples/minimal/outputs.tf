output "ids" {
  description = "Map of table name to id."
  value       = module.tables.ids
}

output "table_endpoint" {
  description = "The account's Table endpoint."
  value       = module.cosmosdb.table_endpoints[local.account_name]
}
