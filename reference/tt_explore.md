# Return One Instance of a Pipeline Target

Reads a stored target from a `tidytargets` pipeline and returns a single
instance so you can inspect it or pipe it onward. A short heading is
issued with [`message()`](https://rdrr.io/r/base/message.html) (target
name and, for collections, which instance). The object itself is
returned, not printed: a top-level call still shows it because R
auto-prints the result; a piped call does not.

For a mapped (patterned) target this is one branch, loaded without
pulling every branch into memory. For a mapped list stored as a single
stem (e.g. `input_list`) this is one list element. For a non-mapped
target the whole object is returned.

If the target has not been built yet, the pipeline is evaluated first
(same incremental `tar_make()` as
[`tt_evaluate()`](https://stemangiola.github.io/tidytargets/reference/tt_evaluate.md)).

## Usage

``` r
tt_explore(tt_input, target_output, index = 1L)

# Default S3 method
tt_explore(tt_input, target_output, index = 1L)

# S3 method for class 'tidytargets'
tt_explore(tt_input, target_output, index = 1L)
```

## Arguments

- tt_input:

  A `tidytargets` object from
  [`tt_initialise()`](https://stemangiola.github.io/tidytargets/reference/tt_initialise.md).

- target_output:

  Character name of the target to inspect.

- index:

  1-based index of the instance to return when the target has more than
  one. Default: `1`.

## Value

The retrieved instance.

## Examples

``` r
if (FALSE) { # \dontrun{
pipeline |> tt_explore("data")
pipeline |> tt_explore("data") |> summary()
pipeline |> tt_explore("data", index = 2)
} # }
```
