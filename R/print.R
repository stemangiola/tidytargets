




#' Print a tidytargets Object
#'
#' @description
#' Prints a summary of a `tidytargets` pipeline object by evaluating it and
#' displaying the resulting targets metadata. Assignment never prints, so an
#' interactive session then says the pipeline is ready to be evaluated,
#' rather than appearing to do nothing.
#'
#' @param x A `tidytargets` object.
#' @param ... Additional arguments passed to `print()`.
#' @return Invisibly returns the printed object (called for its side effect).
#' @importFrom methods show
#' @export
print.tidytargets <- function(x, ...){
  
  x |>
    tt_evaluate() |> 
    print()
}
