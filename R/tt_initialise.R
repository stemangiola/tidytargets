#' Initialise a tidytargets Pipeline
#'
#' @description
#' Sets up and writes a `targets` pipeline script. Saves input paths and
#' configuration to disk, then returns a `tidytargets` object that downstream
#' grammar functions (e.g. `tt_iterate()`, `tt_single()`, `tt_evaluate()`)
#' can extend before the pipeline is executed with `tt_evaluate()`.
#'
#' @param tt_input Named vector of inputs, typically file paths, one element
#'   per unit of iteration (e.g. sample). If names are not set, integer indices
#'   are used.
#' @param store Directory path where pipeline files and targets store are written.
#' @param computing_resources A controller object accepted by
#'   `targets::tar_option_set(controller = )`, such as a `crew` controller or
#'   controller group. `NULL` (the default) runs the pipeline sequentially.
#'   tidytargets does not depend on any compute backend; pass whatever your
#'   deployment uses.
#' @param tier Integer vector (same length as `tt_input`) assigning each input
#'   to a processing tier for tiered execution. Default: all inputs in tier 1.
#' @param debug_step Character name of a single target to debug; passed to
#'   `targets::tar_option_set(debug = ...)`. `NULL` disables debugging.
#' @param verbosity Reporter string passed to `targets::tar_make()`. Defaults to
#'   the current targets configuration value.
#' @param error Error-handling strategy passed to `targets::tar_option_set()`.
#'   `NULL` uses the targets default.
#' @param update Cue mode string for `targets::tar_cue()`, controlling when
#'   targets are re-run. Default: `"thorough"`.
#' @param garbage_collection Numeric interval (in targets) at which R garbage
#'   collection is triggered during the pipeline run. Default: `0` (disabled).
#' @param workspace_on_error Logical; if `TRUE`, saves a workspace snapshot when
#'   a target errors. Default: `FALSE`.
#' @param packages Character vector of R packages loaded on workers. Defaults to
#'   `"tidytargets"`.
#' @return A `tidytargets` S3 object containing the initialisation arguments,
#'   ready to be extended with pipeline step functions.
#'
#' @importFrom glue glue
#' @importFrom targets tar_script
#' @importFrom purrr set_names
#' @import tarchetypes
#' @import targets
#' @export
tt_initialise <- function(tt_input,
                           store =  targets::tar_config_get("store"),
                           computing_resources = NULL,
                           tier = rep(1, length(tt_input)),
                           debug_step = NULL,
                           verbosity = targets::tar_config_get("reporter_make"),
                           error = NULL,
                           update = "thorough",
                           garbage_collection = 0,
                           workspace_on_error = FALSE,
                           packages = "tidytargets"
                          ) {
  
  # Capture all arguments including defaults
  args_list <- as.list(environment())
  
  # if simple names are not set, use integers
  if(tt_input |> names() |> is.null())
    tt_input = tt_input |> set_names(seq_len(length(tt_input)))
  

  # Optionally, you can evaluate the arguments if they are expressions
  args_list <- lapply(args_list, eval, envir = parent.frame())
  
  # Write targets
  dir.create(store, showWarnings = FALSE, recursive = TRUE)
  
  # Save parameters to files
  tt_input |> as.list() |>  saveRDS("input_file.rds")
  tt_input |> names() |> saveRDS("sample_names.rds")
  
  computing_resources |> saveRDS("temp_computing_resources.rds")
  backend_packages <- package_of_object(computing_resources)
  
  # Write pipeline to a file
  {
    library(tidytargets)
    do.call("library", list("dplyr"))
    do.call("library", list("magrittr"))
    do.call("library", list("targets"))
    do.call("library", list("tarchetypes"))
    lapply(bp, function(pkg) do.call("library", list(pkg)))
    
    tar_option_set(
      memory = "transient",
      garbage_collection = g,
      storage = "worker",
      retrieval = "worker",
      error = e,
      debug = d, # Set the target you want to debug.
      cue = tar_cue(mode = u), # Force skip non-debugging outdated targets.
      controller = readRDS("temp_computing_resources.rds"), 
      packages = p,
      trust_object_timestamps = TRUE, 
      workspace_on_error = w
    )
     
    target_list = list(  )
    
    } |> 
    substitute(env = list(d = debug_step, e = error, u = update, g = garbage_collection, w = workspace_on_error, p = packages, bp = backend_packages)) |> 
    tar_script_append2(script = glue("{store}.R"), append = FALSE)

  
  tt_input = 
    list(initialisation = args_list ) |>

    add_class("tidytargets")
  
  
  tt_input |> 
    
    # Sample names
    tt_single("sample_names_file", "sample_names.rds", format = "file") |> 
    
    tt_single(
      target_output = "sample_names", 
      user_function = readRDS |> quote(),
      file = "sample_names_file" |> is_target(), 
      deployment = "main", 
      iterate = "map"
    ) |> 
    
    # Files
    tt_single("input_list_file", "input_file.rds", format = "file") |> 
    
    tt_single(
      target_output = "input_list", 
      user_function = readRDS |> quote(),
      file = "input_list_file" |> is_target(), 
      deployment = "main", 
      iterate = "map"
    )
  
}
