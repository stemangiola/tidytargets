#' Add a Summarising (Non-Iterated) Step to the tidytargets Pipeline
#'
#' @description
#' Appends one non-iterated targets step: a whole object in, a single object
#' out. Use [tt_iterate()] when the step should be mapped or crossed over
#' units. Use [tt_data_list()] (not this function) to bring in a list of
#' units.
#'
#' @param tt_input A `tidytargets` object.
#' @param command An unevaluated expression. Write `name <- expr` to name the
#'   target from the assignment (`tt_single(n <- length(x))`). `{targets}`
#'   tracks dependencies from global symbols in the command (the right-hand
#'   side if you used `<-`). `=` inside the call is argument matching, not
#'   assignment; use `<-`.
#' @param target_output Character name of the output target. Optional if
#'   `command` is `name <- expr`.
#' @param user_function_source_path Optional character path to an R script to
#'   source in the worker before evaluating `command`. `NULL` sources nothing.
#' @param ... Additional factory arguments such as `format`, `deployment`,
#'   or `packages`.
#'
#' @export
tt_single <- function(
    tt_input,
    command = NULL,
    target_output = NULL,
    user_function_source_path = NULL,
    ...
) {
  UseMethod("tt_single")
}

#' @rdname tt_single
#' @export
tt_single.default <- function(
    tt_input,
    command = NULL,
    target_output = NULL,
    user_function_source_path = NULL,
    ...
) {
  stop_if_not_tidytargets()
}

#' @rdname tt_single
#' @export
tt_single.tidytargets <- function(
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

  target_script <- paste0(tt_input$initialisation$store, ".R")
  write_source(user_function_source_path, target_script)

  tar_append(
    fx = quote(tt_factory),
    command = wrap_quote(command),
    target_output = target_output,
    script = target_script,
    ...
  )

  tt_input |>
    c(stats::setNames(
      list(list(command = command, iterate = "none")),
      target_output
    )) |>
    add_class("tidytargets")
}
