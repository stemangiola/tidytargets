#' Add a Single (Non-Iterated) Step to the tidytargets Pipeline
#'
#' @description
#' Appends a single, non-parallelised targets step to the tidytargets pipeline script.
#' Use `hpc_iterate()` instead when the step should be mapped over all samples.
#'
#' @param input_hpc A `tidytargets` object.
#' @param target_output Character name of the output target.
#' @param user_function A quoted function call or function object to execute.
#' @param user_function_source_path Optional character path to an R script to
#'   source in the worker before calling `user_function`. `NULL` sources nothing.
#' @param iterate Iteration mode string. `"none"` disables iteration; `"map"`
#'   maps over input values.
#' @param ... Named arguments passed as target inputs.
#'
#' @export
hpc_single <- function(
    input_hpc,
    target_output = NULL,
    user_function = NULL,
    user_function_source_path = NULL,
    iterate = "none",
    ...
) {
  UseMethod("hpc_single")
}

#' @rdname hpc_single
#' @export
hpc_single.default <- function(
    input_hpc,
    target_output = NULL,
    user_function = NULL,
    user_function_source_path = NULL,
    iterate = "none",
    ...
) {
  stop_if_not_tidytargets()
}

#' @rdname hpc_single
#' @importFrom glue glue
#' @importFrom magrittr %>%
#' @importFrom purrr set_names
#' @export
hpc_single.tidytargets <- function(
    input_hpc,
    target_output = NULL,
    user_function = NULL,
    user_function_source_path = NULL,
    iterate = "none",
    ...
) {
    
    # Target script
    target_script = glue("{input_hpc$initialisation$store}.R")
    
    # Delete line with target in case the user execute the command, without calling hpc_initialise
    target_output |>  delete_lines_with_word(target_script)
    
    # Append source if any
    write_source(user_function_source_path, target_script)
    
    
    tar_append(
      fx = hpc_factory |> quote(),
      target_output = target_output,
      script = target_script,
      user_function = user_function,
      ...
    )
    
    # Add pipeline step
    input_hpc |>
      c(
        as.list(environment())[-1] |> 
          c(list(iterate = iterate)) |> 
          list() |> 
          set_names(target_output)
      ) |>
      add_class("tidytargets")
    
    
  }
