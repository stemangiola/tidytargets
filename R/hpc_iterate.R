#' Add HPC step to pipeline
#'
#' This function adds a new step to the HPC pipeline by appending the appropriate
#' targets to the target script. It allows the user to specify the input and output
#' targets, as well as a custom user function to be applied.
#'
#' @param input_hpc A `tidytargets` object.
#' @param target_output Character name of the output target. `NULL` uses an
#'   auto-generated name.
#' @param user_function A quoted function call to execute per iteration.
#' @param user_function_source_path Optional character path to an R script that
#'   should be sourced in the worker before calling `user_function`. `NULL`
#'   sources nothing.
#' @param ... Named arguments passed as target inputs; use `is_target()` to
#'   reference upstream targets by name.
#'
#' @export
hpc_iterate <- function(
    input_hpc,
    target_output = NULL,
    user_function = NULL,
    user_function_source_path = NULL,
    ...
) {
  UseMethod("hpc_iterate")
}

#' @rdname hpc_iterate
#' @export
hpc_iterate.default <- function(
    input_hpc,
    target_output = NULL,
    user_function = NULL,
    user_function_source_path = NULL,
    ...
) {
  stop_if_not_tidytargets()
}

#' @rdname hpc_iterate
#' @importFrom glue glue
#' @importFrom magrittr %>%
#' @importFrom purrr set_names
#' @export
hpc_iterate.tidytargets <- function(
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
      
    # please, because sometime we set up list target that do not depend on any other ones
    # if tiers is set to NULL, then the target will not acquire the _<tier> suffix
    # I HAVE TO MAKE THIS MORE ELEGANT, AND NOT RELY ON tiers ARGUMENT
    if(input_hpc$initialisation$tier |> get_positions() |> length() < 2){
      iterate_value = "map"
      tiers_value = NULL
    }
      
    else if(
      list(...) |> arguments_to_action(input_hpc, "tiered") |> length() == 0 &
      list(...) |> arguments_to_action(input_hpc, "tier") |> length() == 0
    ){
      iterate_value = "tier"
      tiers_value = NULL
    } else {
      iterate_value = "tiered"
      tiers_value = input_hpc$initialisation$tier |> get_positions()
    }

    tar_append(
      fx = hpc_factory |> quote(),
      tiers = tiers_value ,
      target_output = target_output,
      script = target_script,
      user_function = user_function,
      
      # I HAVE TO IMPROVE the fact that I have to convert to character 
      # because arguments_to_action is also used in expand_tiered_arguments, which needs a named vector
      arguments_to_tier = list(...) |> arguments_to_action(input_hpc, "tier") |> as.character()  , # This "tier" value is decided for each new target below. Usually just at the beginning of the piepline
      arguments_already_tiered = list(...) |> arguments_to_action(input_hpc, "tiered") |> as.character(), # This "tiered" value is decided for each new target below. Ususally every other list targets.
      other_arguments_to_map = list(...) |> arguments_to_action(input_hpc, c("tiered", "map")) |> as.character(), # This "tiered" value is decided for each new target below. Ususally every other list targets.
      ...
    )
  
      
    # Add pipeline step
    input_hpc |>
      c(
        as.list(environment())[-1] |> 
          c(list(iterate = iterate_value)) |> 
          list() |> 
          set_names(target_output) 
      ) |>
      add_class("tidytargets")
    
    
  }
