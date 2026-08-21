# tidytargets NEWS

## tidytargets 0.1.1

* `tt_merge(collapse = TRUE)` flattens a list of lists into a list
  (not with tiers). Two `tt_merge()` calls in a row do not flatten.
* Extracted the reusable tidy `{targets}` grammar from HPCell
  (`tt_initialise()`, `tt_iterate()`, `tt_single()`, `tt_merge()`,
  `tt_report()`, `tt_evaluate()`).
* Grammar functions use the `tt_` prefix (not `hpc_`).
* Dropped single-cell RNA analysis modules, data, and reports.
