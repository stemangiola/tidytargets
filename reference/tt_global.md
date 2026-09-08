# Declare Global Objects Available to Every Target

Records objects from the current session in the pipeline's `$globals`,
which are written into `{store}.R` above the target list, so every
target can use them. Helper functions belong here: a command can call
them directly, and one global function can call another, without passing
either as an argument.

Unlike
[`tt_data()`](https://stemangiola.github.io/tidytargets/reference/tt_data.md),
a global is not a target. It is not a node in the dependency graph, is
not stored in the `_targets` object store, and is not returned by
[`tt_read()`](https://stemangiola.github.io/tidytargets/reference/tt_read.md).
`{targets}` still tracks the globals each command uses, so editing one
invalidates the targets that call it and leaves the rest up to date.

Objects are written as source with
[`deparse()`](https://rdrr.io/r/base/deparse.html), so they must be
self-contained: top-level functions and small constants. An object that
cannot be deparsed, because it holds an environment, a connection, or an
external pointer, is an error here; snapshot it with
[`tt_data()`](https://stemangiola.github.io/tidytargets/reference/tt_data.md).
A closure that depends on its enclosing environment deparses but loses
that environment, so it belongs in
[`tt_data()`](https://stemangiola.github.io/tidytargets/reference/tt_data.md)
too.

Being deparsable is not the same as belonging here. Data structures are
written out element by element, so the script grows with the object: a
one-million-cell assay is around 20 MB of source that `{targets}`
re-parses on every run.
[`tt_data()`](https://stemangiola.github.io/tidytargets/reference/tt_data.md)
writes one `qs` file instead, so anything holding real data belongs
there however well it deparses.

A function keeps the formatting and comments you wrote it with, as long
as the session kept source references (`options(keep.source = )`, `TRUE`
by default in interactive R).

The value is read from the session when you declare it, as
[`tt_data()`](https://stemangiola.github.io/tidytargets/reference/tt_data.md)
snapshots its object. Re-declaring a name replaces the earlier
declaration, because `$globals` is keyed by name, so the script holds
one assignment per global and every target sees the latest one.

## Usage

``` r
tt_global(tt_input, ...)

# Default S3 method
tt_global(tt_input, ...)

# S3 method for class 'tidytargets'
tt_global(tt_input, ...)
```

## Arguments

- tt_input:

  A `tidytargets` object from
  [`tt_initialise()`](https://stemangiola.github.io/tidytargets/reference/tt_initialise.md).

- ...:

  Objects to declare: bare names (`tt_global(edit_covariates)`),
  `name <- value` assignments, or `name = value` arguments. A bare name
  or assignment takes the name from the symbol; a named argument takes
  it from the argument name. An inline expression with no name is an
  error.

## Value

The updated `tidytargets` object.

## Examples

``` r
if (FALSE) { # \dontrun{
add_one <- function(x) x + 1

tt_initialise(store = "store") |>
  tt_global(add_one) |>
  tt_single(two <- add_one(1))
} # }
```
