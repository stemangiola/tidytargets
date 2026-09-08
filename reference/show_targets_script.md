# Print the Targets Script for a tidytargets Pipeline

Writes `{store}.R` for a `tidytargets` object and prints its contents
with a markdown-style heading. Useful for inspecting the pipeline script
while composing steps: the script shown is the one
[`tt_evaluate()`](https://stemangiola.github.io/tidytargets/reference/tt_evaluate.md)
would run.

## Usage

``` r
show_targets_script(pipe)
```

## Arguments

- pipe:

  A `tidytargets` object from
  [`tt_initialise()`](https://stemangiola.github.io/tidytargets/reference/tt_initialise.md).

## Value

Invisibly returns the script lines; called for its side effect of
printing.
