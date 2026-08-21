# Append Targets to the Pipeline Target List

Appends one or more `tar_target` objects to the global `target_list`
used by the tidytargets pipeline script. This function modifies
`target_list` in the calling environment via `<<-`.

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

Invisibly returns `NULL`; called for its side effect of updating
`target_list` in the enclosing environment.
