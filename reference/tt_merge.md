# Add a Merge Step to the tidytargets Pipeline

Appends a targets step that collects and merges results from all
iterated upstream targets into a single aggregate object.

## Usage

``` r
tt_merge(
  tt_input,
  command = NULL,
  target_output = NULL,
  user_function_source_path = NULL,
  ...
)

# Default S3 method
tt_merge(
  tt_input,
  command = NULL,
  target_output = NULL,
  user_function_source_path = NULL,
  ...
)

# S3 method for class 'tidytargets'
tt_merge(
  tt_input,
  command = NULL,
  target_output = NULL,
  user_function_source_path = NULL,
  ...
)
```

## Arguments

- tt_input:

  A `tidytargets` object.

- command:

  An unevaluated expression. Write `name <- expr` to name the target
  from the assignment (`tt_merge(total <- sum(unlist(n)))`). `{targets}`
  tracks dependencies from global symbols in the command (the right-hand
  side if you used `<-`). `=` inside the call is argument matching, not
  assignment; use `<-`.

- target_output:

  Character name of the output target. Optional if `command` is
  `name <- expr`.

- user_function_source_path:

  Optional character path to an R script to source in the worker before
  evaluating `command`. `NULL` sources nothing.

- ...:

  Additional factory arguments such as `format`, `deployment`, or
  `packages`.
