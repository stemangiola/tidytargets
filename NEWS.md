# tidytargets NEWS


## tidytargets 0.0.8

* `tidytargets` objects now have three slots: `$initialisation`, `$metadata`,
  and `$targets`. Grammar verbs append to `$targets` instead of flattening
  target names onto the object, so a target may be named `initialisation`
  or `metadata` without colliding.

## tidytargets 0.0.7

* `tt_iterate()` uses `{targets}` `map()` by default when a command
  mentions more than one mapped input (`tt_data_list()`, mapped
  `tt_initialise()` inputs, or a previous iterate). Length-1 lists are
  omitted from `map()` and ignored when checking equal sizes. Unequal
  sizes error; pass `pattern = "cross"` for a product of branches.
* `tt_single()` is renamed `tt_single()`. It no longer takes `iterate`
  or `n_units`. `tt_data_list()` and mapped `tt_initialise()` inputs register
  list units themselves rather than through `tt_single()`.

## tidytargets 0.0.6

* `tt_import()` and `tt_import_list()` are renamed `tt_data()` and
  `tt_data_list()`.
* `tt_initialise()` snapshots currently attached packages (names from
  `.packages()`, not `.GlobalEnv` objects) onto `tar_option_set(packages = )`
  when `packages` is omitted, and messages that list so you can see what
  workers (including HPC) will load. Local functions and other session objects
  stay out of the pipeline unless you bring them in with `tt_data()` or set
  `user_function_source_path`.

## tidytargets 0.0.5

* Version numbering corrected to pre-alpha `0.0.x` (this release was
  previously labelled `0.4.0`).
* `tt_iterate()`, `tt_single()`, `tt_merge()`, `tt_import()`, and
  `tt_import_list()` accept `name <- expr` to set the target name from the
  assignment (`tt_iterate(fit <- lm(y ~ x))`). `target_output = "fit"` still
  works. `=` inside the call is argument matching, not assignment.

## tidytargets 0.4.0

* `tt_iterate()`, `tt_single()`, `tt_merge()`, and `tt_factory()` take
  `command` before `target_output`.
* `tt_initialise()` no longer requires mapped inputs. `tt_initialise()` alone
  writes the script header; add session objects with `tt_data()`.
* `tt_data()` snapshots a session object onto the store as a single
  (non-mapped) target, so local values can be used as pipeline dependencies.
* `tt_data_list()` snapshots a list as mapped iteration units, for example
  each row of a parameter grid.
* When `tar_make()` fails with an S4 dispatch error on a `list`,
  `tt_evaluate()` adds a hint to use `tt_data_list()` for list inputs that
  should be iterated.
* `tt_explore()` returns one stored instance of a named target (one branch
  of a mapped target, without loading the rest) and messages a short heading
  so you can inspect it or pipe it onward. The target may be unquoted
  (`tt_explore(data)`) or a string, like `targets::tar_read()`.
* Dropped processing tiers (`tier`, `get_positions()`, and the tiered factory
  path). Map iteration is unchanged; elastic `{crew}` controllers replace
  tiered resource groups.
* Printing a pipeline no longer fails with `object 'target_list' not found`.
  The generated script assigns `target_list <- ...` in the script environment
  (instead of `<<-`), and `tt_initialise()` stores an absolute store path.
* Input `.qs` files are written inside the store directory (not the working
  directory), so `print()` / `tt_evaluate()` cannot pick up leftover inputs
  from another pipeline.
* `tt_initialise(store = NULL)` is the default. A unique `./tidytargets-<HASH>`
  directory is created and the path is printed.


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
