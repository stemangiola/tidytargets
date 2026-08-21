# Mark a String as a Targets Target Reference

Converts a character string into an unquoted symbol so that targets
pipeline functions can recognise it as a reference to an upstream target
rather than a literal string value.

## Usage

``` r
is_target(x)
```

## Arguments

- x:

  A character scalar naming the upstream targets target.

## Value

An unquoted symbol (`name`) representing the target, or `NULL` if `x` is
`NULL`.
