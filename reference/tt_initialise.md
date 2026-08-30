# Initialise a tidytargets Pipeline

Sets up and writes a `targets` pipeline script. Saves configuration (and
optional mapped inputs) to disk, then returns a `tidytargets` object
that downstream grammar functions (e.g.
[`tt_data()`](https://stemangiola.github.io/tidytargets/reference/tt_data.md),
[`tt_iterate()`](https://stemangiola.github.io/tidytargets/reference/tt_iterate.md),
[`tt_single()`](https://stemangiola.github.io/tidytargets/reference/tt_single.md),
[`tt_evaluate()`](https://stemangiola.github.io/tidytargets/reference/tt_evaluate.md))
can extend before the pipeline is executed with
[`tt_evaluate()`](https://stemangiola.github.io/tidytargets/reference/tt_evaluate.md).
The graph is not run until you print the object or call
[`tt_evaluate()`](https://stemangiola.github.io/tidytargets/reference/tt_evaluate.md).
Assigning it does not; an interactive session then says the pipeline is
ready to be evaluated, rather than appearing to do nothing.

## Usage

``` r
tt_initialise(
  tt_input = NULL,
  store = NULL,
  computing_resources = NULL,
  debug_step = NULL,
  verbosity = targets::tar_config_get("reporter_make"),
  error = NULL,
  update = "thorough",
  garbage_collection = 0,
  workspace_on_error = FALSE,
  packages = attached_packages(),
  target_output = "input_list"
)
```

## Arguments

- tt_input:

  Named vector of inputs, typically file paths, or a named list of
  in-memory objects, one element per unit of iteration (e.g. sample). If
  names are not set, integer indices are used. `NULL` (the default)
  writes only the script header; add objects later with
  [`tt_data()`](https://stemangiola.github.io/tidytargets/reference/tt_data.md)
  or pass a list here to map over.

- store:

  Directory path where pipeline files and targets store are written.
  `NULL` (the default) writes to `./tidytargets-<HASH>` in the working
  directory and prints that path.

- computing_resources:

  A controller object accepted by
  `targets::tar_option_set(controller = )`, such as a `crew` controller
  or controller group. `NULL` (the default) runs the pipeline
  sequentially. tidytargets does not depend on any compute backend; pass
  whatever your deployment uses.

- debug_step:

  Character name of a single target to debug; passed to
  `targets::tar_option_set(debug = ...)`. `NULL` disables debugging.

- verbosity:

  Reporter string passed to
  [`targets::tar_make()`](https://docs.ropensci.org/targets/reference/tar_make.html).
  Defaults to the current targets configuration value.

- error:

  Error-handling strategy passed to
  [`targets::tar_option_set()`](https://docs.ropensci.org/targets/reference/tar_option_set.html).
  `NULL` uses the targets default.

- update:

  Cue mode string for
  [`targets::tar_cue()`](https://docs.ropensci.org/targets/reference/tar_cue.html),
  controlling when targets are re-run. Default: `"thorough"`.

- garbage_collection:

  Numeric interval (in targets) at which R garbage collection is
  triggered during the pipeline run. Default: `0` (disabled).

- workspace_on_error:

  Logical; if `TRUE`, saves a workspace snapshot when a target errors.
  Default: `FALSE`.

- packages:

  Character vector of R packages loaded on workers, written to
  `tar_option_set(packages = )`. The default is packages currently
  attached in the session
  ([`.packages()`](https://rdrr.io/r/base/zpackages.html)), as names
  only — not objects in the global environment. Pass a character vector
  to override. `"qs2"` is always included.

- target_output:

  Character name of the mapped input target. Default: `"input_list"`.
  Ignored when `tt_input` is `NULL`. A companion file-tracking target is
  registered as `{target_output}_file`.

## Value

A `tidytargets` S3 object containing the initialisation arguments in
`$initialisation` and an empty metadata store (see
[`tt_metadata()`](https://stemangiola.github.io/tidytargets/reference/tt_metadata.md)),
ready to be extended with pipeline step functions. The graph is not run
until you print it or call
[`tt_evaluate()`](https://stemangiola.github.io/tidytargets/reference/tt_evaluate.md).
