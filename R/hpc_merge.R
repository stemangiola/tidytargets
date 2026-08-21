#' Add a Merge Step to the tidytargets Pipeline
#'
#' @description
#' Appends a targets step that collects and merges results from all iterated
#' upstream targets into a single aggregate object.
#'
#' @param input_hpc A `tidytargets` object.
#' @param target_output Character name of the output target.
#' @param user_function A quoted function call to execute for the merge.
#' @param user_function_source_path Optional character path to an R script to
#'   source in the worker. `NULL` sources nothing.
#' @param ... Named arguments passed as target inputs.
#'
#' @export
hpc_merge <- function(
    input_hpc,
    target_output = NULL,
    user_function = NULL,
    user_function_source_path = NULL,
    ...
) {
  UseMethod("hpc_merge")
}

#' @rdname hpc_merge
#' @export
hpc_merge.default <- function(
    input_hpc,
    target_output = NULL,
    user_function = NULL,
    user_function_source_path = NULL,
    ...
) {
  stop_if_not_tidytargets()
}

#' @rdname hpc_merge
#' @importFrom glue glue
#' @importFrom magrittr %>%
#' @importFrom purrr set_names
#' @export
hpc_merge.tidytargets <- function(
    input_hpc,
    target_output = NULL,
    user_function = NULL,
    user_function_source_path = NULL,
    ...
) {
    
    # Check for argument consistency
    check_for_name_value_conflicts(...)
    
    # Target script
    target_script = glue("{input_hpc$initialisation$store}.R")
    
    # Delete line with target in case the user execute the command, without calling hpc_initialise
    target_output |>  delete_lines_with_word(target_script)
    
    # Append source if any
    write_source(user_function_source_path, target_script)
    
    
    # If no tiers
    if(input_hpc$initialisation$tier |> get_positions() |> length() < 2)
      tar_append(
          fx = hpc_factory |> quote(),
          target_output = target_output,
          script = target_script,
          user_function = user_function,
          ...
      )
      
    else{
      
      args = 
        list(...)  |> 
        expand_tiered_arguments(
          tiers = input_hpc$initialisation$tier |> get_positions() |> names(), 
          argument_to_replace = list(...) |> arguments_to_action(input_hpc, "tiered") |> names(),
          tiered_args = list(...) |> arguments_to_action(input_hpc, "tiered") |> names()
        )
      
      # this is needed because I cannot use ellipse (...) anymore, I have to use do.call.
      do.call(tar_append, c(
        list(
          fx = hpc_factory |> quote() |> quote(),
          #tiers = input_hpc$initialisation$tier |> get_positions(),
          target_output = t |> substitute(env = list(t = target_output)) ,
          script = target_script,
          user_function = u |> quote() |> substitute(env = list(u = user_function))
        ),
        args
      ))
    }

    
    
    
    # Add pipeline step
    input_hpc |>
      c(
        as.list(environment())[-1] |> 
          c(list(iterate = "single")) |> 
          list() |> 
          set_names(target_output) 
      ) |>
      add_class("tidytargets")
    
    
  }
