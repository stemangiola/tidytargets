
#' Execute the tidytargets Pipeline
#'
#' @description
#' Closes the pipeline target list and calls `targets::tar_make()` to execute
#' all queued steps. Returns the `tar_meta()` table.
#'
#' The generic records that this store has been run before dispatching, so a
#' subclass `tt_evaluate` method cannot leave the interactive "pipeline is
#' ready" notice standing after a result that has already been shown.
#'
#' @param tt_input A `tidytargets` object constructed by `tt_initialise()` and
#'   extended with one or more pipeline step functions.
#' @return A `tibble` with targets metadata.
#' @name tt_evaluate
#' @export
tt_evaluate <- function(tt_input) {
  store <- if (is.list(tt_input)) tt_input$initialisation$store else NULL
  mark_pipeline_evaluated(store)
  UseMethod("tt_evaluate")
}

#' @rdname tt_evaluate
#' @export
tt_evaluate.default <- function(tt_input) {
  stop_if_not_tidytargets()
}

#' @rdname tt_evaluate
#' @importFrom glue glue
#' @importFrom targets tar_make tar_meta
#' @export
tt_evaluate.tidytargets = function(tt_input) {
  
  #-----------------------#
  # Close pipeline
  #-----------------------#
  
  # Call final list
  tar_script_append({
    target_list 
  }, script = glue("{tt_input$initialisation$store}.R"))
  
  if(tt_input$initialisation$debug_step |> is.null())
    my_callr_function =  callr::r
  else
    my_callr_function =  NULL
  
  tar_make(
    callr_function = my_callr_function,
    script = glue("{tt_input$initialisation$store}.R"),
    store = tt_input$initialisation$store, 
    reporter = tt_input$initialisation$verbosity 
  )
  
  tar_meta(store = glue("{tt_input$initialisation$store}"))
}