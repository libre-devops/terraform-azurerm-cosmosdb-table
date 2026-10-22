# Plan-time tests for the module. The azurerm provider is mocked, so no credentials, no features
# block and no cloud calls are needed:
#   terraform init -backend=false && terraform test

mock_provider "azurerm" {}

variables {
  cosmosdb_account_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ldo-uks-tst-001/providers/Microsoft.DocumentDB/databaseAccounts/cosmos-ldo-uks-tst-01"

  tables = {
    devices     = {}
    escalations = {}
  }
}

run "creates_the_tables_in_the_parsed_account" {
  command = plan

  assert {
    condition = alltrue([
      for t in azurerm_cosmosdb_table.this : t.account_name == "cosmos-ldo-uks-tst-01" && t.resource_group_name == "rg-ldo-uks-tst-001"
    ])
    error_message = "Every table goes in the account the id names, in its resource group."
  }

  assert {
    condition     = length(azurerm_cosmosdb_table.this) == 2 && length(azurerm_cosmosdb_table.this["devices"].autoscale_settings) == 0
    error_message = "One table per entry, with no throughput unless asked (serverless)."
  }
}

run "manual_and_autoscale_throughput_on_a_provisioned_account" {
  command = plan

  variables {
    tables = {
      steady = { throughput = 400 }
      bursty = { autoscale_max_throughput = 4000 }
    }
  }

  assert {
    condition     = azurerm_cosmosdb_table.this["steady"].throughput == 400 && length(azurerm_cosmosdb_table.this["steady"].autoscale_settings) == 0
    error_message = "Manual throughput is passed through."
  }

  assert {
    condition     = one(azurerm_cosmosdb_table.this["bursty"].autoscale_settings).max_throughput == 4000
    error_message = "Autoscale sets its ceiling."
  }
}

run "rejects_a_bad_table_name" {
  command = plan

  variables {
    tables = { "1devices" = {}, "de" = {}, "dev-ices" = {} }
  }

  expect_failures = [var.tables]
}

run "rejects_both_kinds_of_throughput" {
  command = plan

  variables {
    tables = { devices = { throughput = 400, autoscale_max_throughput = 4000 } }
  }

  expect_failures = [var.tables]
}

run "rejects_throughput_off_its_steps" {
  command = plan

  variables {
    tables = { devices = { throughput = 450 }, other = { autoscale_max_throughput = 1500 } }
  }

  expect_failures = [var.tables]
}

run "rejects_an_id_that_is_not_an_account" {
  command = plan

  variables {
    cosmosdb_account_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ldo-uks-tst-001"
  }

  expect_failures = [var.cosmosdb_account_id]
}

run "warns_on_names_that_differ_only_in_case" {
  command = plan

  variables {
    tables = { devices = {}, Devices = {} }
  }

  expect_failures = [check.table_names_differ_beyond_case]
}
