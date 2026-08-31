require_target_output <- function(target_output) {
  if (length(target_output) != 1L || !is.character(target_output) ||
      is.na(target_output) || !nzchar(target_output)) {
    stop(
      "tidytargets says: please name the target with `fit <- ...` or ",
      "target_output = \"fit\".",
      call. = FALSE
    )
  }
}

#' Peel `name <- expr` into a target name and a command
#'
#' @param expr A language object from `substitute()`.
#' @return A list with `name` (character or `NULL`) and `command` (the
#'   right-hand side, or `expr` unchanged).
#' @noRd
peel_assignment <- function(expr) {
  if (!is.call(expr) || length(expr) != 3L ||
      !identical(expr[[1L]], quote(`<-`))) {
    return(list(name = NULL, command = expr))
  }

  lhs <- expr[[2L]]
  if (!is.symbol(lhs)) {
    stop(
      "tidytargets says: the left-hand side of <- must be a name, ",
      "e.g. fit <- lm(y ~ x).",
      call. = FALSE
    )
  }

  list(name = as.character(lhs), command = expr[[3L]])
}

stop_assignment_conflict <- function(from_assignment, target_output) {
  stop(
    "tidytargets says: `", from_assignment, " <-` and target_output = \"",
    target_output, "\" name different targets.",
    call. = FALSE
  )
}

#' Derive `command` and `target_output` from an expression
#'
#' Intermediate step used by `tt_iterate()`, `tt_single()`, `tt_merge()`,
#' `tt_split()`, `tt_data()`, and `tt_data_list()`. The name comes from
#' `name <- expr`,
#' a bare symbol, or `target_output`.
#'
#' @param command A language object from `substitute()`.
#' @param target_output Character name or `NULL`.
#' @return A list with `command` and `target_output`.
#' @noRd
parse_command <- function(command, target_output) {
  peeled <- peel_assignment(command)
  if (!is.null(peeled$name)) {
    if (is.null(target_output)) {
      target_output <- peeled$name
    } else if (!identical(as.character(target_output), peeled$name)) {
      stop_assignment_conflict(peeled$name, target_output)
    }
    command <- peeled$command
  } else if (is.null(target_output) && is.symbol(command)) {
    target_output <- as.character(command)
  }
  require_target_output(target_output)
  list(command = command, target_output = target_output)
}
