# check blocks run after every plan and apply and warn (without blocking) when an invariant is
# violated.

# Table names that differ only in case are distinct keys here, but the same table to Table Storage,
# so a table set that is meant to move between the two services would collide there.
check "table_names_differ_beyond_case" {
  assert {
    condition     = length(distinct([for name in keys(var.tables) : lower(name)])) == length(var.tables)
    error_message = "Two table names differ only in case; Table Storage treats them as one table."
  }
}
