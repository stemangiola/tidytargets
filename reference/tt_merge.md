# Add a Merge Step to the tidytargets Pipeline

Appends a targets step that collects and merges results from all
iterated upstream targets into a single aggregate object.

## Usage

``` r
tt_merge(
  tt_input,
  target_output = NULL,
  user_function = NULL,
  user_function_source_path = NULL,
  ...
)

# Default S3 method
tt_merge(
  tt_input,
  target_output = NULL,
  user_function = NULL,
  user_function_source_path = NULL,
  ...
)

# S3 method for class 'tidytargets'
tt_merge(
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

  Character name of the output target.

- user_function:

  A quoted function call to execute for the merge.

- user_function_source_path:

  Optional character path to an R script to source in the worker. `NULL`
  sources nothing.

- ...:

  Named arguments passed as target inputs.
