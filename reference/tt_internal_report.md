# Internal Factory for Report Targets

Low-level factory that builds
[`tarchetypes::tar_quarto_raw()`](https://docs.ropensci.org/tarchetypes/reference/tar_quarto.html)
calls for pipeline report targets. Not intended to be called by end
users directly.

## Usage

``` r
tt_internal_report(
  tiers = NULL,
  target_output,
  rmd_path,
  render_arguments = quote(list()),
  output_file = NULL,
  arguments_to_tier = c(),
  arguments_already_tiered = c(),
  other_arguments_to_map = c(),
  packages = targets::tar_option_get("packages"),
  deployment = targets::tar_option_get("deployment"),
  ...
)
```

## Arguments

- tiers:

  Named integer list of tier indices. `NULL` or length-1 produces a
  single, non-tiered target.

- target_output:

  Character name of the output target.

- rmd_path:

  Character path to the Quarto (`.qmd`) or R Markdown (`.Rmd`) report
  file.

- render_arguments:

  A quoted [`list()`](https://rdrr.io/r/base/list.html) of parameters
  passed to the report at render time.

- output_file:

  Optional character name for the rendered output file.

- arguments_to_tier:

  Character vector of argument names to tier.

- arguments_already_tiered:

  Character vector of already-tiered arguments.

- other_arguments_to_map:

  Character vector of arguments to map over.

- packages:

  Character vector of R packages to load in the worker.

- deployment:

  Deployment strategy string.

- ...:

  Additional named arguments.

## Value

A `tar_target` object or a list of `tar_target` objects.
