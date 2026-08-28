#' Internal Factory for Iterating Targets
#'
#' @description
#' Low-level factory that builds `tar_target_raw()` calls for each tier in the
#' tidytargets pipeline. Not intended to be called by end users directly.
#'
#' @param tiers Named integer list of tier indices (output of `get_positions()`).
#'   `NULL` or length-1 produces a single, non-tiered target.
#' @param target_output Character name of the output target.
#' @param command An unevaluated expression passed to `tar_target_raw()`.
#'   `{targets}` tracks dependencies from symbols in this expression.
#' @param arguments_to_tier Character vector of target names that should be
#'   tiered (suffixed with the tier index).
#' @param arguments_already_tiered Character vector of target names that have
#'   already been tiered in a prior call.
#' @param other_arguments_to_map Character vector of target names that should
#'   be mapped over without tiering.
#' @param packages Character vector of R packages to load in the worker.
#' @param deployment Deployment strategy string (e.g. `"worker"` or `"main"`).
#' @param format Storage format string for the target value.
#' @param ... Unused; retained so extra factory arguments are ignored.
#' @return A `tar_target` object or a list of `tar_target` objects (one per tier).
#' @export
tt_factory = function(
    tiers = NULL, 
    target_output, 
    command,
    arguments_to_tier = c(), 
    arguments_already_tiered = c(), 
    other_arguments_to_map = c(), 
    packages = targets::tar_option_get("packages") , 
    deployment = targets::tar_option_get("deployment"),
    format = targets::tar_option_get("format"),
    ...
){
  
  if(tiers |> is.null() || tiers |> length() < 2){
    
      tar_target_raw(
        name = target_output |> as.character(), 
        command = command,
        
        # This is in case I am not tiering (e.g. DE analyses) but I need to map
        pattern = build_pattern(other_arguments_to_map = other_arguments_to_map),
        
        iteration = "list", 
        packages = packages,
        deployment = deployment,
        format = format


      )
      
  }

  
  else {
    
    if(command |> deparse() |> str_detect("%>%") |> any()) 
      stop("tidytargets says: no \"%>%\" allowed in the command, please use \"|>\" ")
    
    # Filter out arguments to be tiered from the input command
    if(arguments_to_tier |> length() > 0)
      arguments_already_tiered <- arguments_already_tiered |> str_subset(paste(arguments_to_tier, collapse = "|"), negate = TRUE)
    
    map2(tiers, names(tiers), ~ {
    
      tar_target_raw(
        name = 
          glue("{target_output}_{.y}") |> 
          
          # This is needed because using glue
          as.character() , 
        command = command |>  add_tier_inputs(arguments_already_tiered, .y),
        pattern = 
          build_pattern(
            other_arguments_to_map = glue("{other_arguments_to_map}_{.y}"), 
            arguments_to_tier = arguments_to_tier, 
            index = .x
          ) ,
        iteration = "list",
        packages = packages, 
        deployment = deployment,
        resources = tar_resources(crew = tar_resources_crew(.y)) ,
        format = format
      )
    })
    
  }
   
}
