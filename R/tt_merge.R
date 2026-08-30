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
#'   or `packages`.
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
    resolved <- parse_command(command, target_output)
    command <- resolved$command
    target_output <- resolved$target_output
    rm(resolved)
    
    # Target script
    target_script = glue("{tt_input$initialisation$store}.R")
    
    # Append source if any
    write_source(user_function_source_path, target_script)

    tar_append(
        fx = tt_factory |> quote(),
        command = wrap_quote(command),
        target_output = target_output,
        script = target_script,
        ...
    )

    append_step(
      tt_input,
      target_output,
      as.list(environment())[-1] |>
        c(list(iterate = "single"))
    )
    
    
  }
