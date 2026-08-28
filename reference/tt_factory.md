# Internal Factory for Iterating Targets

Low-level factory that builds a `tar_target_raw()` call for the
tidytargets pipeline. Not intended to be called by end users directly.

## Usage

``` r
tt_factory(
  target_output,
  command,
  other_arguments_to_map = c(),
  packages = targets::tar_option_get("packages"),
  deployment = targets::tar_option_get("deployment"),
  format = targets::tar_option_get("format"),
  ...
)
```

## Arguments

- target_output:

  Character name of the output target.

- command:

  An unevaluated expression passed to `tar_target_raw()`. `{targets}`
  tracks dependencies from symbols in this expression.

- other_arguments_to_map:

  Character vector of target names that should be mapped over.

- packages:

  Character vector of R packages to load in the worker.

- deployment:

  Deployment strategy string (e.g. `"worker"` or `"main"`).

- format:

  Storage format string for the target value.

- ...:

  Unused; retained so extra factory arguments are ignored.

## Value

A `tar_target` object.
