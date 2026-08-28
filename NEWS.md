# tidytargets NEWS

## tidytargets 0.3.0

* `tt_initialise()` accepts a named list of in-memory objects, in addition to
  a named vector of file paths.
* `tt_initialise(target_output = )` names the mapped input target (default
  `"input_list"`).
* `tt_iterate()`, `tt_single()`, `tt_merge()`, and `tt_report()` take an
  unevaluated expression (`command` / `params`). `{targets}` tracks
  dependencies from symbols in that expression. The `user_function` plus
  `is_target()` argument list is gone.
* Pipeline storage uses `{qs2}` (`format = "qs"`) instead of RDS.
* The building-blocks vignette now starts from a named list rather than RDS
  files.

## tidytargets 0.1.0

* Extracted the reusable tidy `{targets}` grammar from HPCell
  (`tt_initialise()`, `tt_iterate()`, `tt_single()`, `tt_merge()`,
  `tt_report()`, `tt_evaluate()`).
* Grammar functions use the `tt_` prefix (not `hpc_`).
* Added `tt_metadata()` to get and set free-form metadata on a `tidytargets`
  object.
* Dropped single-cell RNA analysis modules, data, and reports.
