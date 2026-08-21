# Internal Factory for Iterating Targets

Low-level factory that builds `tar_target_raw()` calls for each tier in
the tidytargets pipeline. Not intended to be called by end users
directly.

## Usage

``` r
tt_factory(
  tiers = NULL,
  target_output,
  user_function,
  arguments_to_tier = c(),
  arguments_already_tiered = c(),
  other_arguments_to_map = c(),
  packages = targets::tar_option_get("packages"),
  deployment = targets::tar_option_get("deployment"),
  format = targets::tar_option_get("format"),
  ...
)
```

## Arguments

- tiers:

  Named integer list of tier indices (output of
  [`get_positions()`](https://stemangiola.github.io/tidytargets/reference/get_positions.md)).
  `NULL` or length-1 produces a single, non-tiered target.

- target_output:

  Character name of the output target.

- user_function:

  A quoted function call to execute for this target.

- arguments_to_tier:

  Character vector of argument names that should be tiered (suffixed
  with the tier index).

- arguments_already_tiered:

  Character vector of argument names that have already been tiered in a
  prior call.

- other_arguments_to_map:

  Character vector of argument names that should be mapped over without
  tiering.

- packages:

  Character vector of R packages to load in the worker.

- deployment:

  Deployment strategy string (e.g. `"worker"` or `"main"`).

- format:

  Storage format string for the target value.

- ...:

  Additional named arguments passed as target inputs.

## Value

A `tar_target` object or a list of `tar_target` objects (one per tier).
