# Add a Summarising (Non-Iterated) Step to the tidytargets Pipeline

Appends one non-iterated targets step: a whole object in, a single
object out. Use
[`tt_iterate()`](https://stemangiola.github.io/tidytargets/reference/tt_iterate.md)
when the step should be mapped or crossed over units. Use
[`tt_data_list()`](https://stemangiola.github.io/tidytargets/reference/tt_data_list.md)
(not this function) to bring in a list of units.

## Usage

``` r
tt_single(
  tt_input,
  command = NULL,
  target_output = NULL,
  user_function_source_path = NULL,
  ...
)

# Default S3 method
tt_single(
  tt_input,
  command = NULL,
  target_output = NULL,
  user_function_source_path = NULL,
  ...
)

# S3 method for class 'tidytargets'
tt_single(
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

- ...:

  Additional factory arguments such as `format`, `deployment`, or
  `packages`.
