# Add a Single (Non-Iterated) Step to the tidytargets Pipeline

Appends a single, non-parallelised targets step to the tidytargets
pipeline script. Use
[`tt_iterate()`](https://stemangiola.github.io/tidytargets/reference/tt_iterate.md)
instead when the step should be mapped over all samples.

## Usage

``` r
tt_single(
  tt_input,
  target_output = NULL,
  user_function = NULL,
  user_function_source_path = NULL,
  iterate = "none",
  ...
)

# Default S3 method
tt_single(
  tt_input,
  target_output = NULL,
  user_function = NULL,
  user_function_source_path = NULL,
  iterate = "none",
  ...
)

# S3 method for class 'tidytargets'
tt_single(
  tt_input,
  target_output = NULL,
  user_function = NULL,
  user_function_source_path = NULL,
  iterate = "none",
  ...
)
```

## Arguments

- tt_input:

  A `tidytargets` object.

- target_output:

  Character name of the output target.

- user_function:

  A quoted function call or function object to execute.

- user_function_source_path:

  Optional character path to an R script to source in the worker before
  calling `user_function`. `NULL` sources nothing.

- iterate:

  Iteration mode string. `"none"` disables iteration; `"map"` maps over
  input values.

- ...:

  Named arguments passed as target inputs.
