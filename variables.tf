variable "cosmosdb_account_id" {
  description = "Resource id of the API for Table account the tables go in (pass the cosmosdb-account module's ids output). Its name and resource group are parsed from it."
  type        = string

  validation {
    condition     = try(provider::azurerm::parse_resource_id(var.cosmosdb_account_id).resource_type, "") == "databaseAccounts"
    error_message = "cosmosdb_account_id must be a Cosmos DB account id of the form /subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.DocumentDB/databaseAccounts/<name>."
  }
}

variable "tables" {
  description = <<-EOT
    Tables to create in the account, keyed by table name (3 to 63 letters and digits, starting with a
    letter, the rule Table Storage shares, so a table can move between the two). On a serverless
    account leave both throughput settings unset: serverless has no provisioned throughput. On a
    provisioned account set at most one of:
      throughput                manual RU/s, at least 400, in hundreds
      autoscale_max_throughput  the autoscale ceiling, at least 1000, in thousands
    With neither, a provisioned table takes the account's default.
  EOT
  type = map(object({
    throughput               = optional(number)
    autoscale_max_throughput = optional(number)
  }))
  default = {}

  validation {
    condition     = alltrue([for name in keys(var.tables) : can(regex("^[A-Za-z][A-Za-z0-9]{2,62}$", name))])
    error_message = "Each table name must be 3 to 63 letters and digits, starting with a letter."
  }

  validation {
    condition     = alltrue([for t in values(var.tables) : t.throughput == null || t.autoscale_max_throughput == null])
    error_message = "A table takes throughput or autoscale_max_throughput, not both."
  }

  validation {
    condition = alltrue([
      for t in values(var.tables) :
      (t.throughput == null ? true : t.throughput >= 400 && t.throughput % 100 == 0) &&
      (t.autoscale_max_throughput == null ? true : t.autoscale_max_throughput >= 1000 && t.autoscale_max_throughput % 1000 == 0)
    ])
    error_message = "throughput must be at least 400 in hundreds, and autoscale_max_throughput at least 1000 in thousands."
  }
}
