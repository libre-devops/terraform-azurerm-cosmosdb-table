output "ids" {
  description = "Map of table name to id."
  value       = module.tables.ids
}

output "names" {
  description = "The table names."
  value       = module.tables.names
}
