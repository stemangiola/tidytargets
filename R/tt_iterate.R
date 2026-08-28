#' Add HPC step to pipeline
#'
#' This function adds a new step to the HPC pipeline by appending the appropriate
#' targets to the target script. It allows the user to specify the input and output
#' targets, as well as a custom user function to be applied.
#'
#' @param tt_input A `tidytargets` object.
#' @param target_output Character name of the output target. `NULL` uses an
#'   auto-generated name.
#' @param command An unevaluated expression. `{targets}` tracks dependencies from
#'   global symbols in this expression (including upstream target names). Mapped
#'   targets referenced here also set the iteration pattern.
#' @param user_function_source_path Optional character path to an R script that
#'   should be sourced in the worker before evaluating `command`. `NULL`
#'   sources nothing.
#' @param ... Additional factory arguments such as `format`, `deployment`,
#'   or `packages`.
#'
#' @export
tt_iterate <- function(
    tt_input,
    target_output = NULL,
    command = NULL,
    user_function_source_path = NULL,
    ...
) {
  UseMethod("tt_iterate")
}

#' @rdname tt_iterate
#' @export
tt_iterate.default <- function(
    tt_input,
    target_output = NULL,
    command = NULL,
    user_function_source_path = NULL,
    ...
) {
  stop_if_not_tidytargets()
}

#' @rdname tt_iterate
#' @importFrom glue glue
#' @importFrom purrr set_names
#' @export
tt_iterate.tidytargets <- function(
    tt_input,
    target_output = NULL,
    command = NULL,
    user_function_source_path = NULL,
    ...
) {
    
    command <- substitute(command)
    
    # Target script
    target_script = glue("{tt_input$initialisation$store}.R")
    
    # Delete line with target in case the user execute the command, without calling tt_initialise
    target_output |>  delete_lines_with_word(target_script)
    
    # Append source if any
    write_source(user_function_source_path, target_script)

    tar_append(
      fx = tt_factory |> quote(),
      target_output = target_output,
      script = target_script,
      command = wrap_quote(command),
      other_arguments_to_map = command_targets(command, tt_input, "map"),
      ...
    )
  
      
    # Add pipeline step
    tt_input |>
      c(
        as.list(environment())[-1] |> 
          c(list(iterate = "map")) |> 
          list() |> 
          set_names(target_output) 
      ) |>
      add_class("tidytargets")
    
    
  }
