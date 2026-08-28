# Add a Report Step to the tidytargets Pipeline

Appends a Quarto/R Markdown rendering step to the tidytargets pipeline,
which generates an HTML report using
[`tarchetypes::tar_quarto_raw()`](https://docs.ropensci.org/tarchetypes/reference/tar_quarto.html).

## Usage

``` r
tt_report(
  tt_input,
  target_output = NULL,
  rmd_path = NULL,
  params = list(),
  ...
)

# Default S3 method
tt_report(
  tt_input,
  target_output = NULL,
  rmd_path = NULL,
  params = list(),
  ...
)

# S3 method for class 'tidytargets'
tt_report(
  tt_input,
  target_output = NULL,
  rmd_path = NULL,
  params = list(),
  ...
)
```

## Arguments

- tt_input:

  A `tidytargets` object.

- target_output:

  Character name of the output target for the rendered report.

- rmd_path:

  Character path to the `.qmd` or `.Rmd` report file.

- params:

  An unevaluated [`list()`](https://rdrr.io/r/base/list.html) of report
  parameters. `{targets}` tracks dependencies from symbols in this
  expression (including upstream target names).

- ...:

  Additional factory arguments such as `deployment` or `packages`.
