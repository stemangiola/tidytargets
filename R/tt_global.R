#' Declare Global Objects Available to Every Target
#'
#' @description
#' Records objects from the current session in the pipeline's `$globals`, which
#' [write_script()] writes into `{store}.R` above the target list, so every
#' target can use them. Helper functions belong here: a command can call them
#' directly, and one global function can call another, without passing either
#' as an argument.
#'
#' Unlike [tt_data()], a global is not a target. It is not a node in the
#' dependency graph, is not stored in the `_targets` object store, and is not
#' returned by [tt_read()]. `{targets}` still tracks the globals each command
#' uses, so editing one invalidates the targets that call it and leaves the
#' rest up to date.
#'
#' Objects are written as source with `deparse()`, so they must be
#' self-contained: top-level functions and small constants. A closure that
#' depends on its enclosing environment, or a large or non-deparsable object
#' such as a fitted model or a `SingleCellExperiment`, belongs in [tt_data()].
#' A function keeps the formatting and comments you wrote it with, as long as
#' the session kept source references (`options(keep.source = )`, `TRUE` by
#' default in interactive R).
#'
#' The value is read from the session when you declare it, as [tt_data()]
#' snapshots its object. Re-declaring a name replaces the earlier declaration,
#' because `$globals` is keyed by name, so the script holds one assignment per
#' global and every target sees the latest one.
#'
#' @param tt_input A `tidytargets` object from [tt_initialise()].
#' @param ... Objects to declare: bare names (`tt_global(edit_covariates)`),
#'   `name <- value` assignments, or `name = value` arguments. A bare name or
#'   assignment takes the name from the symbol; a named argument takes it from
#'   the argument name. An inline expression with no name is an error.
#' @return The updated `tidytargets` object.
#'
#' @examples
#' \dontrun{
#' add_one <- function(x) x + 1
#'
#' tt_initialise(store = "store") |>
#'   tt_global(add_one) |>
#'   tt_single(two <- add_one(1))
#' }
#' @name tt_global
#' @export
tt_global <- function(tt_input, ...) {
  UseMethod("tt_global")
}

#' @rdname tt_global
#' @export
tt_global.default <- function(tt_input, ...) {
  stop_if_not_tidytargets()
}

#' @rdname tt_global
#' @export
tt_global.tidytargets <- function(tt_input, ...) {
  exprs <- as.list(substitute(list(...)))[-1L]
  if (length(exprs) == 0L) {
    stop(
      "tidytargets says: tt_global() needs at least one object, ",
      "e.g. tt_global(my_helper).",
      call. = FALSE
    )
  }

  supplied <- names(exprs)
  if (is.null(supplied)) supplied <- rep("", length(exprs))
  envir <- parent.frame()

  for (i in seq_along(exprs)) {
    named <- if (nzchar(supplied[[i]])) supplied[[i]] else NULL
    resolved <- parse_command(exprs[[i]], named)

    # Deparsed here rather than at write time: a global is a snapshot of the
    # session object, and write_script() cannot reach this frame to evaluate
    # the symbol later. "useSource" keeps the formatting and comments the
    # function was written with, when the session kept source references.
    code <- deparse(
      eval(resolved$command, envir),
      control = c("useSource", "keepInteger", "keepNA", "niceNames", "showAttributes")
    )
    code[[1L]] <- paste0(resolved$target_output, " <- ", code[[1L]])
    tt_input$globals[[resolved$target_output]] <- code
  }

  schedule_pipeline_ready_notice(tt_input$initialisation$store)
  tt_input
}
