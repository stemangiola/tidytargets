# Add HPC step to pipeline

This function adds a new step to the HPC pipeline by appending the
appropriate targets to the target script. It allows the user to specify
the input and output targets, as well as a custom user function to be
applied.

## Usage

``` r
tt_iterate(
  tt_input,
  command = NULL,
  target_output = NULL,
  user_function_source_path = NULL,
  pattern = c("map", "cross"),
  ...
)

# Default S3 method
tt_iterate(
  tt_input,
  command = NULL,
  target_output = NULL,
  user_function_source_path = NULL,
  pattern = c("map", "cross"),
  ...
)

# S3 method for class 'tidytargets'
tt_iterate(
  tt_input,
  command = NULL,
  target_output = NULL,
  user_function_source_path = NULL,
  pattern = c("map", "cross"),
  ...
)
```

## Arguments

- tt_input:

  A `tidytargets` object.

- command:

  An unevaluated expression. Write `name <- expr` to name the target
  from the assignment (`tt_iterate(fit <- lm(y ~ x))`). `{targets}`
  tracks dependencies from global symbols in the command (the right-hand
  side if you used `<-`), using the same static analysis as `{targets}`
  (`$column` is not a dependency). Mapped targets referenced here also
  set the iteration pattern. `=` inside the call is argument matching,
  not assignment; use `<-`.

- target_output:

  Character name of the output target. Optional if `command` is
  `name <- expr`.

- user_function_source_path:

  Optional character path to an R script that should be sourced in the
  worker before evaluating `command`. `NULL` sources nothing.

- pattern:

  `"map"` (the default) or `"cross"`. `"map"` pairs mapped inputs;
  `{targets}` errors at make time if their lengths differ. Pass
  `"cross"` for a product of branches. A single mapped input is always
  `map()`. With two or more mapped inputs, the chosen pattern is
  messaged; `cross()` names the targets being crossed.

- ...:

  Additional factory arguments such as `format`, `deployment`, or
  `packages`.
