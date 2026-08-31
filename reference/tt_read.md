# Read a Stored Pipeline Target

Reads a stored target from a `tidytargets` pipeline and returns the full
value. For a mapped (patterned) target this is every branch (typically a
list). For a non-mapped target this is the stored object.

If the target has not been built yet, the pipeline is evaluated first
(same incremental `tar_make()` as
[`tt_evaluate()`](https://stemangiola.github.io/tidytargets/reference/tt_evaluate.md)).

Compare with
[`tt_explore()`](https://stemangiola.github.io/tidytargets/reference/tt_explore.md),
which returns one instance at a time without loading every branch.

## Usage

``` r
tt_read(tt_input, target_output)

# Default S3 method
tt_read(tt_input, target_output)

# S3 method for class 'tidytargets'
tt_read(tt_input, target_output)
```

## Arguments

- tt_input:

  A `tidytargets` object from
  [`tt_initialise()`](https://stemangiola.github.io/tidytargets/reference/tt_initialise.md).

- target_output:

  Name of the target to read, unquoted (`data`) or as a string
  (`"data"`), like
  [`targets::tar_read()`](https://docs.ropensci.org/targets/reference/tar_read.html).

## Value

The stored target value.

## Examples

``` r
if (FALSE) { # \dontrun{
pipeline |> tt_read(data)
pipeline |> tt_read("data")
} # }
```
