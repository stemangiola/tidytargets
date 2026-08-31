#' Return One Instance of a Pipeline Target
#'
#' @description
#' Reads a stored target from a `tidytargets` pipeline and returns a single
#' instance so you can inspect it or pipe it onward. A short heading is
#' issued with `message()` (target name and, for collections, which instance).
#' The object itself is returned, not printed: a top-level call still shows
#' it because R auto-prints the result; a piped call does not.
#'
#' For a mapped (patterned) target this is one branch, loaded without pulling
#' every branch into memory. For a mapped list stored as a single stem
#' (e.g. `input_list`) this is one list element. For a non-mapped target the
#' whole object is returned. Use [tt_read()] to load every branch at once.
#'
#' If the target has not been built yet, the pipeline is evaluated first
#' (same incremental `tar_make()` as `tt_evaluate()`).
#'
#' @param tt_input A `tidytargets` object from `tt_initialise()`.
#' @param target_output Name of the target to inspect, unquoted (`data`) or
#'   as a string (`"data"`), like `targets::tar_read()`.
#' @param index 1-based index of the instance to return when the target has
#'   more than one. Default: `1`.
#'
#' @return The retrieved instance.
#'
#' @examples
#' \dontrun{
#' pipeline |> tt_explore(data)
#' pipeline |> tt_explore(data) |> summary()
#' pipeline |> tt_explore("data", index = 2)
#' }
#' @name tt_explore
#' @export
tt_explore <- function(tt_input, target_output, index = 1L) {
  UseMethod("tt_explore")
}

#' @rdname tt_explore
#' @export
tt_explore.default <- function(tt_input, target_output, index = 1L) {
  stop_if_not_tidytargets()
}

#' @rdname tt_explore
#' @importFrom targets tar_meta tar_read_raw tar_exist_objects
#' @export
tt_explore.tidytargets <- function(tt_input, target_output, index = 1L) {
  target_output <- as_target_name(substitute(target_output))
  store <- tt_input$initialisation$store
  if (!output_is_built(store, target_output)) {
    tt_evaluate(tt_input)
  }

  instance <- read_output_instance(tt_input, target_output, index)

  n <- instance$n
  x <- instance$value
  if (!is.null(n) && n > 1L) {
    message("## ", target_output, " (instance ", index, " of ", n, ")")
  } else {
    message("## ", target_output)
  }
  x
}

#' Target name from an unquoted symbol or a string, like tar_read()
#'
#' @noRd
as_target_name <- function(expr) {
  if (is.symbol(expr)) return(as.character(expr))
  if (is.character(expr) && length(expr) == 1L) return(expr)
  as.character(expr)
}

#' Metadata row for a single target, without tidyselect on an external vector
#'
#' @noRd
meta_for_target <- function(store, name) {
  meta <- targets::tar_meta(store = store)
  meta[meta$name == name, , drop = FALSE]
}

#' Whether a named target has a completed stored value
#'
#' @noRd
output_is_built <- function(store, name) {
  if (!file.exists(file.path(store, "meta", "meta"))) return(FALSE)

  meta <- meta_for_target(store, name)
  if (nrow(meta) == 0L) return(FALSE)

  err <- meta$error
  if (length(err) && !is.na(err) && nzchar(as.character(err))) return(FALSE)

  if (identical(meta$type, "pattern")) {
    children <- meta$children[[1]]
    children <- children[!is.na(children)]
    length(children) > 0L &&
      all(targets::tar_exist_objects(children, store = store))
  } else {
    isTRUE(targets::tar_exist_objects(name, store = store))
  }
}

#' Read one instance of a stored target
#'
#' @return A list with `value` (the instance) and `n` (how many instances
#'   exist, or `NULL` when the target is not a collection of instances).
#' @noRd
read_output_instance <- function(tt_input, target_output, index) {
  store <- tt_input$initialisation$store
  meta <- meta_for_target(store, target_output)

  if (identical(meta$type, "pattern")) {
    children <- meta$children[[1]]
    children <- children[!is.na(children)]
    n <- length(children)
    value <- targets::tar_read_raw(
      target_output,
      branches = index,
      store = store
    )
    if (is.list(value) && !is.object(value) && length(value) == 1L) {
      value <- value[[1]]
    }
    return(list(value = value, n = n))
  }

  value <- targets::tar_read_raw(target_output, store = store)
  iterate <- tt_input$targets[[target_output]]$iterate
  if (identical(iterate, "map") && is.list(value) && !is.object(value) &&
      length(value) > 0L) {
    n <- length(value)
    return(list(value = value[[index]], n = n))
  }

  list(value = value, n = NULL)
}
