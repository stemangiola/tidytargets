#' Split a Stem Target into Mapped Units
#'
#' @description
#' Inverse of [tt_merge()]: appends a non-patterned target whose command
#' returns a list, and marks it as mapped units so later [tt_iterate()]
#' steps that mention `target_output` branch over the elements.
#'
#' Use this when the list is produced **in the pipeline** (for example
#' splitting a [tt_data()] grid). To snapshot a list from the current
#' session, use [tt_data_list()] instead.
#'
#' The number of units is taken from `length()` of the command result when
#' that can be evaluated in the current session (typical after [tt_data()]).
#' Pass `n_units` only to override, or when the length is not known yet.
#'
#' @param tt_input A `tidytargets` object.
#' @param command An unevaluated expression that returns a list. Write
#'   `name <- expr` to name the target from the assignment
#'   (`tt_split(settings <- grid |> group_split(row_number()))`).
#'   `{targets}` tracks dependencies from global symbols in the command
#'   (the right-hand side if you used `<-`). `=` inside the call is
#'   argument matching, not assignment; use `<-`.
#' @param target_output Character name of the output target. Optional if
#'   `command` is `name <- expr`.
#' @param n_units Optional positive integer override for the number of
#'   list elements. `NULL` (the default) infers it from the command when
#'   possible.
#' @param user_function_source_path Optional character path to an R script
#'   to source in the worker before evaluating `command`. `NULL` sources
#'   nothing.
#' @param ... Additional factory arguments such as `format`, `deployment`,
#'   or `packages`.
#'
#' @export
tt_split <- function(
    tt_input,
    command = NULL,
    target_output = NULL,
    n_units = NULL,
    user_function_source_path = NULL,
    ...
) {
  UseMethod("tt_split")
}

#' @rdname tt_split
#' @export
tt_split.default <- function(
    tt_input,
    command = NULL,
    target_output = NULL,
    n_units = NULL,
    user_function_source_path = NULL,
    ...
) {
  stop_if_not_tidytargets()
}

#' @rdname tt_split
#' @export
tt_split.tidytargets <- function(
    tt_input,
    command = NULL,
    target_output = NULL,
    n_units = NULL,
    user_function_source_path = NULL,
    ...
) {
  command <- substitute(command)
  resolved <- parse_command(command, target_output)
  command <- resolved$command
  target_output <- resolved$target_output
  rm(resolved)

  if (is.null(n_units)) {
    n_units <- n_units_from_command(command, tt_input, parent.frame())
  } else {
    ok <- length(n_units) == 1L &&
      is.numeric(n_units) &&
      !is.na(n_units) &&
      n_units >= 1 &&
      n_units == as.integer(n_units)
    if (!ok) {
      stop(
        "tidytargets says: n_units must be a single positive integer.",
        call. = FALSE
      )
    }
    n_units <- as.integer(n_units)
  }

  target_script <- paste0(tt_input$initialisation$store, ".R")
  write_source(user_function_source_path, target_script)

  tar_append(
    fx = quote(tt_factory),
    command = wrap_quote(command),
    target_output = target_output,
    script = target_script,
    ...
  )

  append_step(
    tt_input,
    target_output,
    list(
      command = command,
      iterate = "map",
      n_units = n_units
    )
  )
}

#' Length of a split command evaluated from session or store snapshots
#'
#' Used by [tt_split()] so `n_units` need not be passed. Bindings come from
#' [tt_data()] `.qs` files when present, otherwise from `envir`. Errors and
#' non-list values leave `n_units` unknown.
#'
#' @param command A language object.
#' @param pipe A `tidytargets` object.
#' @param envir Fallback environment (the calling session).
#' @return A positive integer, or `NULL`.
#' @noRd
n_units_from_command <- function(command, pipe, envir) {
  bindings <- list()
  if (is.language(command)) {
    deps <- targets::tar_deps_raw(command)
    store <- pipe$initialisation$store
    for (nm in deps) {
      qs_path <- file.path(store, paste0(nm, "_data.qs"))
      if (file.exists(qs_path)) {
        bindings[[nm]] <- qs2::qs_read(qs_path)
      }
    }
  }
  env <- list2env(bindings, parent = envir)
  x <- tryCatch(eval(command, env), error = function(e) NULL)
  if (is.null(x) || !is.list(x) || is.data.frame(x)) return(NULL)
  n <- length(as.list(x))
  if (n < 1L) return(NULL)
  as.integer(n)
}
