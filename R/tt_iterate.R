#' Add HPC step to pipeline
#'
#' This function adds a new step to the HPC pipeline by appending the appropriate
#' targets to the target script. It allows the user to specify the input and output
#' targets, as well as a custom user function to be applied.
#'
#' @param tt_input A `tidytargets` object.
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
tt_iterate <- function(
    tt_input,
    target_output = NULL,
    user_function = NULL,
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
    user_function = NULL,
    user_function_source_path = NULL,
    ...
) {
  stop_if_not_tidytargets()
}

#' @rdname tt_iterate
#' @importFrom glue glue
#' @importFrom magrittr %>%
#' @importFrom purrr set_names
#' @export
tt_iterate.tidytargets <- function(
    tt_input,
    target_output = NULL,
    user_function = NULL,
    user_function_source_path = NULL,
    ...
) {
    
    # Check for argument consistency
    check_for_name_value_conflicts(...)
    
    # Target script
    target_script = glue("{tt_input$initialisation$store}.R")
    
    # Delete line with target in case the user execute the command, without calling tt_initialise
    target_output |>  delete_lines_with_word(target_script)
    
    # Append source if any
    write_source(user_function_source_path, target_script)
      
    # please, because sometime we set up list target that do not depend on any other ones
    # if tiers is set to NULL, then the target will not acquire the _<tier> suffix
    # I HAVE TO MAKE THIS MORE ELEGANT, AND NOT RELY ON tiers ARGUMENT
    if(tt_input$initialisation$tier |> get_positions() |> length() < 2){
      iterate_value = "map"
      tiers_value = NULL
    }
      
    else if(
      list(...) |> arguments_to_action(tt_input, "tiered") |> length() == 0 &
      list(...) |> arguments_to_action(tt_input, "tier") |> length() == 0
    ){
      iterate_value = "tier"
      tiers_value = NULL
    } else {
      iterate_value = "tiered"
      tiers_value = tt_input$initialisation$tier |> get_positions()
    }

    tar_append(
      fx = tt_factory |> quote(),
      tiers = tiers_value ,
      target_output = target_output,
      script = target_script,
      user_function = user_function,
      
      # I HAVE TO IMPROVE the fact that I have to convert to character 
      # because arguments_to_action is also used in expand_tiered_arguments, which needs a named vector
      arguments_to_tier = list(...) |> arguments_to_action(tt_input, "tier") |> as.character()  , # This "tier" value is decided for each new target below. Usually just at the beginning of the piepline
      arguments_already_tiered = list(...) |> arguments_to_action(tt_input, "tiered") |> as.character(), # This "tiered" value is decided for each new target below. Ususally every other list targets.
      other_arguments_to_map = list(...) |> arguments_to_action(tt_input, c("tiered", "map")) |> as.character(), # This "tiered" value is decided for each new target below. Ususally every other list targets.
      ...
    )
  
      
    # Add pipeline step
    tt_input |>
      c(
        as.list(environment())[-1] |> 
          c(list(iterate = iterate_value)) |> 
          list() |> 
          set_names(target_output) 
      ) |>
      add_class("tidytargets")
    
    
  }
