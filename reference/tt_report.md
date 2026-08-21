# Add a Report Step to the tidytargets Pipeline

Appends a Quarto/R Markdown rendering step to the tidytargets pipeline,
which generates an HTML report using
[`tarchetypes::tar_quarto_raw()`](https://docs.ropensci.org/tarchetypes/reference/tar_quarto.html).

## Usage

``` r
tt_report(tt_input, target_output = NULL, rmd_path = NULL, ...)

# Default S3 method
tt_report(tt_input, target_output = NULL, rmd_path = NULL, ...)

# S3 method for class 'tidytargets'
tt_report(tt_input, target_output = NULL, rmd_path = NULL, ...)
```

## Arguments

- tt_input:

  A `tidytargets` object.

- target_output:

  Character name of the output target for the rendered report.

- rmd_path:

  Character path to the `.qmd` or `.Rmd` report file.

- ...:

  Named arguments passed as report parameters.
