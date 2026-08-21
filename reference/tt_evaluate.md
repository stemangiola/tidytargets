# Execute the tidytargets Pipeline

Closes the pipeline target list and calls
[`targets::tar_make()`](https://docs.ropensci.org/targets/reference/tar_make.html)
to execute all queued steps. Returns the `tar_meta()` table.

## Usage

``` r
tt_evaluate(tt_input)

# Default S3 method
tt_evaluate(tt_input)

# S3 method for class 'tidytargets'
tt_evaluate(tt_input)
```

## Arguments

- tt_input:

  A `tidytargets` object constructed by
  [`tt_initialise()`](https://stemangiola.github.io/tidytargets/reference/tt_initialise.md)
  and extended with one or more pipeline step functions.

## Value

A `tibble` with targets metadata.
