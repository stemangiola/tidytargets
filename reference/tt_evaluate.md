# Execute the tidytargets Pipeline

Closes the pipeline target list and calls
[`targets::tar_make()`](https://docs.ropensci.org/targets/reference/tar_make.html)
to execute all queued steps. Returns the `tar_meta()` table.

If a target fails with an S4 method-dispatch error on a `list`
(typically because a list was brought in with
[`tt_import()`](https://stemangiola.github.io/tidytargets/reference/tt_import.md)
instead of
[`tt_import_list()`](https://stemangiola.github.io/tidytargets/reference/tt_import_list.md)),
the error is rethrown with a hint to use
[`tt_import_list()`](https://stemangiola.github.io/tidytargets/reference/tt_import_list.md).

The generic records that this store has been run before dispatching, so
a subclass `tt_evaluate` method cannot leave the interactive "pipeline
is ready" notice standing after a result that has already been shown.

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
