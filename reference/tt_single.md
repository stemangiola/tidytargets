# Add a Single (Non-Iterated) Step to the tidytargets Pipeline

Appends a single, non-parallelised targets step to the tidytargets
pipeline script. Use
[`tt_iterate()`](https://stemangiola.github.io/tidytargets/reference/tt_iterate.md)
instead when the step should be mapped over all samples.

## Usage

``` r
tt_single(
  tt_input,
  command = NULL,
  target_output = NULL,
  user_function_source_path = NULL,
  iterate = "none",
  ...
)

# Default S3 method
tt_single(
  tt_input,
  command = NULL,
  target_output = NULL,
  user_function_source_path = NULL,
  iterate = "none",
  ...
)

# S3 method for class 'tidytargets'
tt_single(
  tt_input,
  command = NULL,
  target_output = NULL,
  user_function_source_path = NULL,
  iterate = "none",
  ...
)
```

## Arguments

- tt_input:

  A `tidytargets` object.

- command:

  An unevaluated expression. Write `name <- expr` to name the target
  from the assignment (`tt_single(n <- length(x))`). `{targets}` tracks
  dependencies from global symbols in the command (the right-hand side
  if you used `<-`). `=` inside the call is argument matching, not
  assignment; use `<-`.

- target_output:

  Character name of the output target. Optional if `command` is
  `name <- expr`.

- user_function_source_path:

  Optional character path to an R script to source in the worker before
  evaluating `command`. `NULL` sources nothing.

- iterate:

  Iteration mode string stored on the pipeline object. `"none"` disables
  iteration; `"map"` marks the result as mapped for later steps.

- ...:

  Additional factory arguments such as `format`, `deployment`, or
  `packages`.
