#' Add a Merge Step to the tidytargets Pipeline
#'
#' @description
#' Appends a targets step that collects and merges results from all iterated
#' upstream targets into a single aggregate object.
#'
#' @param tt_input A `tidytargets` object.
#' @param command An unevaluated expression. Write `name <- expr` to name the
#'   target from the assignment (`tt_merge(total <- sum(unlist(n)))`).
#'   `{targets}` tracks dependencies from global symbols in the command (the
#'   right-hand side if you used `<-`). `=` inside the call is argument
#'   matching, not assignment; use `<-`.
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
tt_merge <- function(
    tt_input,
    command = NULL,
    target_output = NULL,
    user_function_source_path = NULL,
    ...
) {
  UseMethod("tt_merge")
}

#' @rdname tt_merge
#' @export
tt_merge.default <- function(
    tt_input,
    command = NULL,
    target_output = NULL,
    user_function_source_path = NULL,
    ...
) {
  stop_if_not_tidytargets()
}

#' @rdname tt_merge
#' @importFrom glue glue
#' @export
tt_merge.tidytargets <- function(
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
    rm(resolved)
    
    append_step(
      tt_input,
      target_output,
      list(
        command = command,
        iterate = "single",
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
