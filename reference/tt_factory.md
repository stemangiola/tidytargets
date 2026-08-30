# Internal Factory for Iterating Targets

Low-level factory that builds a `tar_target_raw()` call for the
tidytargets pipeline. Not intended to be called by end users directly.

## Usage

``` r
tt_factory(
  command,
  target_output,
  other_arguments_to_map = c(),
  pattern_type = "map",
  packages = targets::tar_option_get("packages"),
  deployment = targets::tar_option_get("deployment"),
  format = targets::tar_option_get("format"),
  ...
)
```

## Arguments

- command:

  An unevaluated expression passed to `tar_target_raw()`. `{targets}`
  tracks dependencies from symbols in this expression.

- target_output:

  Character name of the output target.

- other_arguments_to_map:

  Character vector of target names that should be mapped or crossed
  over.

- pattern_type:

  `"map"` (one branch per tuple) or `"cross"` (one branch per
  combination).

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
