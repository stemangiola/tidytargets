# Get positions of each unique element in a vector

This function takes a vector and returns a named list where each unique
element of the input vector maps to the positions at which it occurs.

## Usage

``` r
get_positions(input_vector)
```

## Arguments

- input_vector:

  A vector of elements.

## Value

A named list where each name is a unique element from the input vector
and each value is a vector of positions where that element occurs.

## Examples

``` r
input_vector <- c("a", "a", "b", "c", "a")
positions_list <- get_positions(input_vector)
print(positions_list)
#> $a
#> [1] 1 2 5
#> 
#> $b
#> [1] 3
#> 
#> $c
#> [1] 4
#> 
```
