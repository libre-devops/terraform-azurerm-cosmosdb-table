# Changelog

All notable changes to this module are recorded here.

## 1.0.0

### Added
- API for Table tables keyed by name, in an existing Cosmos DB account passed by id, made through
  Azure Resource Manager so they work with key based authentication off.
- Manual throughput or an autoscale ceiling per table on a provisioned account, validated to their
  steps, and neither on a serverless one.
- Table names validated to the rule Table Storage shares, and a check warning on names that differ
  only in case.
