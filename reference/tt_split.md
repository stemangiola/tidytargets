# Split a Stem Target into Mapped Units

Inverse of
[`tt_merge()`](https://stemangiola.github.io/tidytargets/reference/tt_merge.md):
appends a non-patterned target whose command returns a list, and marks
it as mapped units so later
[`tt_iterate()`](https://stemangiola.github.io/tidytargets/reference/tt_iterate.md)
steps that mention `target_output` branch over the elements.

Use this when the list is produced **in the pipeline** (for example
splitting a
[`tt_data()`](https://stemangiola.github.io/tidytargets/reference/tt_data.md)
grid). To snapshot a list from the current session, use
[`tt_data_list()`](https://stemangiola.github.io/tidytargets/reference/tt_data_list.md)
instead.

## Usage

``` r
tt_split(
  tt_input,
  command = NULL,
  target_output = NULL,
  user_function_source_path = NULL,
  ...
)

# Default S3 method
tt_split(
  tt_input,
  command = NULL,
  target_output = NULL,
  user_function_source_path = NULL,
  ...
)

# S3 method for class 'tidytargets'
tt_split(
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

  An unevaluated expression that returns a list. Write `name <- expr` to
  name the target from the assignment
  (`tt_split(settings <- grid |> group_split(row_number()))`).
  `{targets}` tracks dependencies from global symbols in the command
  (the right-hand side if you used `<-`). `=` inside the call is
  argument matching, not assignment; use `<-`.

- target_output:

  Character name of the output target. Optional if `command` is
  `name <- expr`.

- user_function_source_path:

  Optional character path to an R script to source in the worker before
  evaluating `command`. `NULL` sources nothing.

- ...:

  Additional factory arguments such as `format`, `deployment`, or
  `packages`.
