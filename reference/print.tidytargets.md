# Print a tidytargets Object

Prints a summary of a `tidytargets` pipeline object by evaluating it and
displaying the resulting targets metadata. Assignment never prints, so
an interactive session then says the pipeline is ready to be evaluated,
rather than appearing to do nothing.

## Usage

``` r
# S3 method for class 'tidytargets'
print(x, ...)
```

## Arguments

- x:

  A `tidytargets` object.

- ...:

  Additional arguments passed to
  [`print()`](https://rdrr.io/r/base/print.html).

## Value

Invisibly returns the printed object (called for its side effect).
