# Import a Session Object as a Pipeline Target

Snapshots an object from the current R session onto the pipeline store
and registers it as a single (non-mapped) target. Unlike
[`tt_initialise()`](https://stemangiola.github.io/tidytargets/reference/tt_initialise.md),
the object is not split into iteration units: a list or a Bioconductor
object is stored as one value.

The value is written to disk immediately (`qs_save()`). `{targets}` then
tracks that file and reads it back when the target runs, so later
[`tt_single()`](https://stemangiola.github.io/tidytargets/reference/tt_single.md)
/
[`tt_iterate()`](https://stemangiola.github.io/tidytargets/reference/tt_iterate.md)
commands can use `target_output` as a dependency. A local variable
mentioned only in `command` is not imported; use this function for that.

If `target_output` is omitted, the name of `x` is used
(`tt_import(pipeline, airway)` registers `"airway"`), or the left-hand
side of an assignment (`tt_import(pipeline, airway <- se)`).

For a list of units to map over (for example each row of a parameter
grid), use
[`tt_import_list()`](https://stemangiola.github.io/tidytargets/reference/tt_import_list.md)
instead.

## Usage

``` r
tt_import(tt_input, x, target_output = NULL)

# Default S3 method
tt_import(tt_input, x, target_output = NULL)

# S3 method for class 'tidytargets'
tt_import(tt_input, x, target_output = NULL)
```

## Arguments

- tt_input:

  A `tidytargets` object from
  [`tt_initialise()`](https://stemangiola.github.io/tidytargets/reference/tt_initialise.md).

- x:

  Object in the current session to snapshot into the store.

- target_output:

  Character name of the target. `NULL` (the default) uses the symbol
  supplied as `x`, or the left-hand side of `x <- value`.

## Value

The updated `tidytargets` object.

## Examples

``` r
if (FALSE) { # \dontrun{
pipeline <- tt_initialise(store = "store") |>
  tt_import(airway, target_output = "airway")
} # }
```
