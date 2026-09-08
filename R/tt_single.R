#' Add a Summarising (Non-Iterated) Step to the tidytargets Pipeline
#'
#' @description
#' Appends one non-iterated targets step: a whole object in, a single object
#' out. Use [tt_iterate()] when the step should be mapped or crossed over
#' units. Use [tt_data_list()] to bring a session list in as units, or
#' [tt_split()] to turn a pipeline stem into units.
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
#'   `packages`, or `resources`. Evaluated in your session, except
#'   `resources`, which is written into the script as source: pass
#'   `tar_resources(crew = tar_resources_crew(controller = "name"))` where the
#'   step is declared, without `quote()`, rather than an object built
#'   beforehand.
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
  envir <- parent.frame()
  resolved <- parse_command(command, target_output)
  command <- resolved$command
  target_output <- resolved$target_output

  append_step(
    tt_input,
    target_output,
    list(
      command = command,
      iterate = "none",
      source = user_function_source_path,
      factory = factory_call(
        quote(tt_factory),
        list(command = wrap_quote(command), target_output = target_output),
        substitute(list(...)),
        envir
      )
    )
  )
}
