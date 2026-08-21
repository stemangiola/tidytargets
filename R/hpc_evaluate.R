
#' Execute the tidytargets Pipeline
#'
#' @description
#' Closes the pipeline target list and calls `targets::tar_make()` to execute
#' all queued steps. Returns the `tar_meta()` table.
#'
#' @param input_hpc A `tidytargets` object constructed by `hpc_initialise()` and
#'   extended with one or more pipeline step functions.
#' @return A `tibble` with targets metadata.
#' @name hpc_evaluate
#' @export
hpc_evaluate <- function(input_hpc) {
  UseMethod("hpc_evaluate")
}

#' @rdname hpc_evaluate
#' @importFrom glue glue
#' @importFrom targets tar_make tar_meta
#' @export
hpc_evaluate.tidytargets = function(input_hpc) {
  
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