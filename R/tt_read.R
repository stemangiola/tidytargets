#' Read a Stored Pipeline Target
#'
#' @description
#' Reads a stored target from a `tidytargets` pipeline and returns the full
#' value. For a mapped (patterned) target this is every branch (typically a
#' list). For a non-mapped target this is the stored object.
#'
#' If the target has not been built yet, the pipeline is evaluated first
#' (same incremental `tar_make()` as `tt_evaluate()`).
#'
#' Compare with [tt_explore()], which returns one instance at a time without
#' loading every branch.
#'
#' @param tt_input A `tidytargets` object from `tt_initialise()`.
#' @param target_output Name of the target to read, unquoted (`data`) or
#'   as a string (`"data"`), like `targets::tar_read()`.
#'
#' @return The stored target value.
#'
#' @examples
#' \dontrun{
#' pipeline |> tt_read(data)
#' pipeline |> tt_read("data")
#' }
#' @name tt_read
#' @export
tt_read <- function(tt_input, target_output) {
  UseMethod("tt_read")
}

#' @rdname tt_read
#' @export
tt_read.default <- function(tt_input, target_output) {
  stop_if_not_tidytargets()
}

#' @rdname tt_read
#' @importFrom targets tar_read_raw
#' @export
tt_read.tidytargets <- function(tt_input, target_output) {
  target_output <- as_target_name(substitute(target_output))
  store <- tt_input$initialisation$store
  if (!output_is_built(store, target_output)) {
    tt_evaluate(tt_input)
  }
  targets::tar_read_raw(target_output, store = store)
}
