# tidytargets NEWS

## tidytargets 0.1.0

* Extracted the reusable tidy `{targets}` grammar from HPCell
  (`tt_initialise()`, `tt_iterate()`, `tt_single()`, `tt_merge()`,
  `tt_report()`, `tt_evaluate()`).
* Grammar functions use the `tt_` prefix (not `hpc_`).
* Added `tt_metadata()` to get and set free-form metadata on a `tidytargets`
  object.
* Dropped single-cell RNA analysis modules, data, and reports.
