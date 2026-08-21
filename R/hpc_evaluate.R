
#' Execute the tidytargets Pipeline
#'
#' @description
#' Closes the pipeline target list and calls `targets::tar_make()` to execute
#' all queued steps. Returns the `tar_meta()` table.
#'
#' @param input_hpc A `tidytargets` object constructed by `initialise_hpc()` and
#'   extended with one or more pipeline step functions.
#' @return A `tibble` with targets metadata.
#' @name evaluate_hpc
#' @export
evaluate_hpc <- function(input_hpc) {
  UseMethod("evaluate_hpc")
}

#' @importFrom glue glue
#' @importFrom targets tar_make tar_meta
#' @export
evaluate_hpc.tidytargets = function(input_hpc) {
  
  #-----------------------#
  # Close pipeline
  #-----------------------#
  
  # Call final list
  tar_script_append({
    target_list 
  }, script = glue("{input_hpc$initialisation$store}.R"))
  
  if(input_hpc$initialisation$debug_step |> is.null())
    my_callr_function =  callr::r
  else
    my_callr_function =  NULL
  
  tar_make(
    callr_function = my_callr_function,
    script = glue("{input_hpc$initialisation$store}.R"),
    store = input_hpc$initialisation$store, 
    reporter = input_hpc$initialisation$verbosity 
  )
  
  tar_meta(store = glue("{input_hpc$initialisation$store}"))
}