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
#' @param tt_input A `tidytargets` object.
#' @param command An unevaluated expression that returns a list. Write
#'   `name <- expr` to name the target from the assignment
#'   (`tt_split(settings <- grid |> group_split(row_number()))`).
#'   `{targets}` tracks dependencies from global symbols in the command
#'   (the right-hand side if you used `<-`). `=` inside the call is
#'   argument matching, not assignment; use `<-`.
#' @param target_output Character name of the output target. Optional if
#'   `command` is `name <- expr`.
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
    user_function_source_path = NULL,
    ...
) {
  command <- substitute(command)
  resolved <- parse_command(command, target_output)
  command <- resolved$command
  target_output <- resolved$target_output
  rm(resolved)

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
    list(command = command, iterate = "map")
  )
}
