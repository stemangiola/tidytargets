




#' Print a tidytargets Object
#'
#' @description
#' Prints a summary of a `tidytargets` pipeline object by evaluating it and
#' displaying the resulting targets metadata.
#'
#' @param x A `tidytargets` object.
#' @param ... Additional arguments passed to `print()`.
#' @return Invisibly returns the printed object (called for its side effect).
#' @importFrom methods show
#' @export
print.tidytargets <- function(x, ...){
  
  x |>
    evaluate_hpc() |> 
    print()
}
