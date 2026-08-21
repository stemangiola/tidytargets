# Add HPC step to pipeline

This function adds a new step to the HPC pipeline by appending the
appropriate targets to the target script. It allows the user to specify
the input and output targets, as well as a custom user function to be
applied.

## Usage

``` r
tt_iterate(
  tt_input,
  target_output = NULL,
  user_function = NULL,
  user_function_source_path = NULL,
  ...
)

# Default S3 method
tt_iterate(
  tt_input,
  target_output = NULL,
  user_function = NULL,
  user_function_source_path = NULL,
  ...
)

# S3 method for class 'tidytargets'
tt_iterate(
  tt_input,
  target_output = NULL,
  user_function = NULL,
  user_function_source_path = NULL,
  ...
)
```

## Arguments

- tt_input:

  A `tidytargets` object.

- target_output:

  Character name of the output target. `NULL` uses an auto-generated
  name.

- user_function:

  A quoted function call to execute per iteration.

- user_function_source_path:

  Optional character path to an R script that should be sourced in the
  worker before calling `user_function`. `NULL` sources nothing.

- ...:

  Named arguments passed as target inputs; use
  [`is_target()`](https://stemangiola.github.io/tidytargets/reference/is_target.md)
  to reference upstream targets by name.
