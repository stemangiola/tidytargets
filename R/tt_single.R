#' Add a Single (Non-Iterated) Step to the tidytargets Pipeline
#'
#' @description
#' Appends a single, non-parallelised targets step to the tidytargets pipeline script.
#' Use `tt_iterate()` instead when the step should be mapped over all samples.
#'
#' @param tt_input A `tidytargets` object.
#' @param target_output Character name of the output target.
#' @param command An unevaluated expression. `{targets}` tracks dependencies from
#'   global symbols in this expression (including upstream target names).
#' @param user_function_source_path Optional character path to an R script to
#'   source in the worker before evaluating `command`. `NULL` sources nothing.
#' @param iterate Iteration mode string stored on the pipeline object. `"none"`
#'   disables iteration; `"map"` marks the result as mapped for later steps.
#' @param ... Additional factory arguments such as `format`, `deployment`,
#'   or `packages`.
#'
#' @export
tt_single <- function(
    tt_input,
    target_output = NULL,
    command = NULL,
    user_function_source_path = NULL,
    iterate = "none",
    ...
) {
  UseMethod("tt_single")
}

#' @rdname tt_single
#' @export
tt_single.default <- function(
    tt_input,
    target_output = NULL,
    command = NULL,
    user_function_source_path = NULL,
    iterate = "none",
    ...
) {
  stop_if_not_tidytargets()
}

#' @rdname tt_single
#' @importFrom glue glue
#' @importFrom magrittr %>%
#' @importFrom purrr set_names
#' @export
tt_single.tidytargets <- function(
    tt_input,
    target_output = NULL,
    command = NULL,
    user_function_source_path = NULL,
    iterate = "none",
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
      ...
    )
    
    # Add pipeline step
    tt_input |>
      c(
        as.list(environment())[-1] |> 
          c(list(iterate = iterate)) |> 
          list() |> 
          set_names(target_output)
      ) |>
      add_class("tidytargets")
    
    
  }
