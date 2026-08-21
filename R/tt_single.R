#' Add a Single (Non-Iterated) Step to the tidytargets Pipeline
#'
#' @description
#' Appends a single, non-parallelised targets step to the tidytargets pipeline script.
#' Use `tt_iterate()` instead when the step should be mapped over all samples.
#'
#' @param tt_input A `tidytargets` object.
#' @param target_output Character name of the output target.
#' @param user_function A quoted function call or function object to execute.
#' @param user_function_source_path Optional character path to an R script to
#'   source in the worker before calling `user_function`. `NULL` sources nothing.
#' @param iterate Iteration mode string. `"none"` disables iteration; `"map"`
#'   maps over input values.
#' @param ... Named arguments passed as target inputs.
#'
#' @export
tt_single <- function(
    tt_input,
    target_output = NULL,
    user_function = NULL,
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
    user_function = NULL,
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
    user_function = NULL,
    user_function_source_path = NULL,
    iterate = "none",
    ...
) {
    
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
      user_function = user_function,
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
