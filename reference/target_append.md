# Append Targets to the Pipeline Target List

Combines an existing list of `tar_target` objects with one or more new
targets. The generated pipeline script assigns the result back to
`target_list`.

## Usage

``` r
target_append(target_list, ...)
```

## Arguments

- target_list:

  The existing list of `tar_target` objects to append to.

- ...:

  One or more `tar_target` objects to append.

## Value

The combined list of targets.
