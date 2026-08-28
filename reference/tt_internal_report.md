# Internal Factory for Report Targets

Low-level factory that builds
[`tarchetypes::tar_quarto_raw()`](https://docs.ropensci.org/tarchetypes/reference/tar_quarto.html)
calls for pipeline report targets. Not intended to be called by end
users directly.

## Usage

``` r
tt_internal_report(
  target_output,
  rmd_path,
  render_arguments = quote(list()),
  output_file = NULL,
  packages = targets::tar_option_get("packages"),
  deployment = targets::tar_option_get("deployment"),
  ...
)
```

## Arguments

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

- packages:

  Character vector of R packages to load in the worker.

- deployment:

  Deployment strategy string.

- ...:

  Additional named arguments.

## Value

A `tar_target` object.
