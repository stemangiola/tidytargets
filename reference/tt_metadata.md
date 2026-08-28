# Get or Set Free-Form Metadata on a tidytargets Object

Reads and writes the metadata store of a `tidytargets` object, a
free-form named list for information that is not part of the pipeline
itself, such as API endpoints, credentials handles, dataset identifiers
or provenance notes.

Called with no additional arguments the metadata list is returned.
Called with named arguments the entries are merged into the existing
metadata and the `tidytargets` object is returned, so the call can sit
anywhere in a pipeline. Passing `NULL` as a value removes that entry.

Metadata lives in the pipeline object only; it is not written to the
targets script and is not available to workers. To pass values to
workers, include them in the `command` expression of
[`tt_iterate()`](https://stemangiola.github.io/tidytargets/reference/tt_iterate.md)
or
[`tt_single()`](https://stemangiola.github.io/tidytargets/reference/tt_single.md).

## Usage

``` r
tt_metadata(tt_input, ...)

# Default S3 method
tt_metadata(tt_input, ...)

# S3 method for class 'tidytargets'
tt_metadata(tt_input, ...)
```

## Arguments

- tt_input:

  A `tidytargets` object.

- ...:

  Named values to store. Omit to read the metadata instead.

## Value

The metadata list when reading, or the updated `tidytargets` object when
writing.

## Details

The store is held under a dot-prefixed element of the object. `targets`
rejects target names beginning with a dot, so the store can never be
shadowed by a target the user adds, and metadata places no restriction
on the names passed to `target_output`.

## Examples

``` r
if (FALSE) { # \dontrun{
pipeline <- files |>
  tt_initialise(store = "store") |>
  tt_metadata(api_url = "https://api.example.org", api_version = 2)

pipeline |> tt_metadata()
tt_metadata(pipeline)$api_url
} # }
```
