#' Declare Global Objects Available to Every Target
#'
#' @description
#' Writes objects from the current session into the initialisation section of
#' `{store}.R`, above the target list, so every target can use them. Helper
#' functions belong here: a command can call them directly, and one global
#' function can call another, without passing either as an argument.
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
#'
#' Re-declaring a name appends a second assignment, and the script is sourced
#' in order, so the last declaration is the one every target sees. The earlier
#' copy stays visible in [show_targets_script()]; call [tt_initialise()] again
#' to start the script from scratch.
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
  script <- paste0(tt_input$initialisation$store, ".R")

  for (i in seq_along(exprs)) {
    named <- if (nzchar(supplied[[i]])) supplied[[i]] else NULL
    resolved <- parse_command(exprs[[i]], named)
    write_global(
      resolved$target_output,
      eval(resolved$command, envir),
      script
    )
  }

  schedule_pipeline_ready_notice(tt_input$initialisation$store)
  tt_input
}

#' Write one global assignment into the script header
#'
#' `tt_initialise()` ends its header with `target_list <- list()`. Globals go
#' just above it so the script reads as configuration first, then targets.
#' A global declared after a step in the pipe is still visible to that step,
#' because factory commands are quoted and evaluated once the whole script has
#' been sourced. Order among globals does matter: the insertion point is
#' recomputed each call, so a later declaration lands after an earlier one and
#' wins.
#'
#' @param name Character name to assign to.
#' @param value The value to deparse into source.
#' @param script Path to the `{targets}` script (`{store}.R`).
#' @return `NULL`, invisibly.
#' @noRd
write_global <- function(name, value, script) {
  code <- deparse(value)
  code[[1L]] <- paste0(name, " <- ", code[[1L]])

  lines <- readLines(script)
  at <- grep("^\\s*target_list\\s*<-\\s*list\\(\\)\\s*$", lines)

  if (length(at) == 0L) {
    writeLines(c(lines, code), script)
  } else {
    writeLines(append(lines, code, after = at[[1L]] - 1L), script)
  }

  invisible()
}
