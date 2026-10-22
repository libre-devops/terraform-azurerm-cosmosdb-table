# API for Table tables keyed by name, in an existing account passed by id and parsed. Created through
# Azure Resource Manager, so they work with the account's key based authentication off. Throughput is
# manual or autoscale on a provisioned account, and absent on a serverless one. Data plane access to
# the tables is granted by the account's own roles (the cosmosdb-account module's
# table_role_assignments).
resource "azurerm_cosmosdb_table" "this" {
  for_each = var.tables

  name                = each.key
  resource_group_name = local.resource_group_name
  account_name        = local.account_name
  throughput          = each.value.throughput

  dynamic "autoscale_settings" {
    for_each = each.value.autoscale_max_throughput != null ? [each.value.autoscale_max_throughput] : []
    content {
      max_throughput = autoscale_settings.value
    }
  }
}
