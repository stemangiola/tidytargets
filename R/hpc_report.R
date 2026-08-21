#' Add a Report Step to the tidytargets Pipeline
#'
#' @description
#' Appends a Quarto/R Markdown rendering step to the tidytargets pipeline, which
#' generates an HTML report using `tarchetypes::tar_quarto_raw()`.
#'
#' @param input_hpc A `tidytargets` object.
#' @param target_output Character name of the output target for the rendered report.
#' @param rmd_path Character path to the `.qmd` or `.Rmd` report file.
#' @param ... Named arguments passed as report parameters.
#'
#' @importFrom glue glue
#' @importFrom magrittr %>%
#' @importFrom purrr set_names
#' @export
hpc_report = function(input_hpc, target_output = NULL, rmd_path = NULL, ...) {
    
    # # Check for argument consistency
    # check_for_name_value_conflicts(...)
    # 
    # Target script
    target_script = glue("{input_hpc$initialisation$store}.R")
    
    # Delete line with target in case the user execute the command, without calling hpc_initialise
    target_output |>  delete_lines_with_word(target_script)
    
    external_dir <- file.path(input_hpc$initialisation$store, "external")
    dir.create(external_dir, showWarnings = FALSE, recursive = TRUE)
    external_dir <- normalizePath(external_dir)
    
    # If no tiers
    if(input_hpc$initialisation$tier |> get_positions() |> length() < 2)
      tar_append(
        fx = hpc_internal_report |> quote(),
        target_output = target_output,
        script = target_script,
        rmd_path = rmd_path,
        output_file = glue("{external_dir}/{target_output}") |> as.character(),
        render_arguments = substitute(quote(expr), list(expr = list(params = list(...)))) # Add quotation
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

  #' Internal Factory for Report Targets
#'
#' @description
#' Low-level factory that builds `tarchetypes::tar_quarto_raw()` calls for
#' pipeline report targets. Not intended to be called by end users directly.
#'
#' @param tiers Named integer list of tier indices. `NULL` or length-1 produces
#'   a single, non-tiered target.
#' @param target_output Character name of the output target.
#' @param rmd_path Character path to the Quarto (`.qmd`) or R Markdown (`.Rmd`)
#'   report file.
#' @param render_arguments A quoted `list()` of parameters passed to the report
#'   at render time.
#' @param output_file Optional character name for the rendered output file.
#' @param arguments_to_tier Character vector of argument names to tier.
#' @param arguments_already_tiered Character vector of already-tiered arguments.
#' @param other_arguments_to_map Character vector of arguments to map over.
#' @param packages Character vector of R packages to load in the worker.
#' @param deployment Deployment strategy string.
#' @param ... Additional named arguments.
#' @return A `tar_target` object or a list of `tar_target` objects.
#' @export
hpc_internal_report = function(
    tiers = NULL, 
    target_output, 
    rmd_path,
    render_arguments = quote(list()),
    output_file = NULL,
    arguments_to_tier = c(), 
    arguments_already_tiered = c(), 
    other_arguments_to_map = c(), 
    packages = targets::tar_option_get("packages") , 
    deployment = targets::tar_option_get("deployment"),
    ...
){
  

  if(tiers |> is.null() || tiers |> length() < 2){
    
    tar_quarto_raw(
      name = target_output |> as.character(), 
      path = rmd_path,
      output_file = output_file,
      execute_params = render_arguments,
      # This is in case I am not tiering (e.g. DE analyses) but I need to map
      # pattern = build_pattern(other_arguments_to_map = other_arguments_to_map),
      
      # iteration = "list", 
      packages = packages,
      deployment = deployment
      
      
    )
    
  }
  
  
  else {
    
    # Filter out arguments to be tiered from the input command
    if(arguments_to_tier |> length() > 0)
      arguments_already_tiered <- arguments_already_tiered |> str_subset(paste(arguments_to_tier, collapse = "|"), negate = TRUE)
    
    map2(tiers, names(tiers), ~ {
      
      tar_quarto_raw(
        name = 
          glue("{target_output}_{.y}") |> 
          
          # This is needed because using glue
          as.character() , 
        pattern = 
          build_pattern(
            other_arguments_to_map = glue("{other_arguments_to_map}_{.y}"), 
            arguments_to_tier = arguments_to_tier, 
            index = .x
          ) ,
        # iteration = "list",
        packages = packages, 
        deployment = deployment,
        resources = tar_resources(crew = tar_resources_crew(.y)) 
      )
    })
    
  }
  
}