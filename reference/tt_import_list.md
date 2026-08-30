# Import a List of Units as a Mapped Pipeline Target

Snapshots a list from the current R session onto the store and registers
it as a **mapped** target, one iteration unit per element. This is the
import analogue of passing a named list to
[`tt_initialise()`](https://stemangiola.github.io/tidytargets/reference/tt_initialise.md):
later
[`tt_iterate()`](https://stemangiola.github.io/tidytargets/reference/tt_iterate.md)
steps that mention `target_output` are mapped over the elements.

Typical use is a parameter grid split into rows, e.g.
`tt_import_list(settings <- grid |> split(seq_len(nrow(grid))))` or
[`dplyr::group_split()`](https://dplyr.tidyverse.org/reference/group_split.html).
Unnamed lists are named with integer indices, the same way
[`tt_initialise()`](https://stemangiola.github.io/tidytargets/reference/tt_initialise.md)
names unnamed inputs.

If `target_output` is omitted, the name of `x` is used, or the left-hand
side of an assignment (`tt_import_list(settings <- rows)`). An inline
expression such as `grid |> group_split(row_number())` is not a name, so
name it with `<-` or pass `target_output`.

## Usage

``` r
tt_import_list(tt_input, x, target_output = NULL)

# Default S3 method
tt_import_list(tt_input, x, target_output = NULL)

# S3 method for class 'tidytargets'
tt_import_list(tt_input, x, target_output = NULL)
```

## Arguments

- tt_input:

  A `tidytargets` object from
  [`tt_initialise()`](https://stemangiola.github.io/tidytargets/reference/tt_initialise.md).

- x:

  A list (or list-like object, such as the result of
  [`dplyr::group_split()`](https://dplyr.tidyverse.org/reference/group_split.html)).
  Each element becomes one mapped unit.

- target_output:

  Character name of the mapped target. `NULL` (the default) uses the
  symbol supplied as `x`, or the left-hand side of `x <- value`.

## Value

The updated `tidytargets` object.

## Examples

``` r
if (FALSE) { # \dontrun{
grid <- expand.grid(alpha = c(0, 1), lambda = c(0.1, 1))
pipeline <- tt_initialise(store = "store") |>
  tt_import_list(settings <- grid |> split(seq_len(nrow(grid))))
} # }
```
