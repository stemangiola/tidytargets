
#' Execute the tidytargets Pipeline
#'
#' @description
#' Closes the pipeline target list and calls `targets::tar_make()` to execute
#' all queued steps. Returns the `tar_meta()` table.
#'
#' @param tt_input A `tidytargets` object constructed by `tt_initialise()` and
#'   extended with one or more pipeline step functions.
#' @return A `tibble` with targets metadata.
#' @name tt_evaluate
#' @export
tt_evaluate <- function(tt_input) {
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

  script <- glue("{tt_input$initialisation$store}.R")

  # {targets} eval()s the script and uses the last expression as the pipeline.
  # Each factory already assigns `target_list <- ...`; a trailing `target_list`
  # is enough to return it, and is stripped first so print() is idempotent.
  lines <- readLines(script)
  lines <- lines[!grepl("^\\s*target_list\\s*$", lines)]
  writeLines(c(lines, "target_list"), script)
  
  if(tt_input$initialisation$debug_step |> is.null())
    my_callr_function =  callr::r
  else
    my_callr_function =  NULL
  
  tar_make(
    callr_function = my_callr_function,
    script = script,
    store = tt_input$initialisation$store, 
    reporter = tt_input$initialisation$verbosity 
  )
  
  tar_meta(store = glue("{tt_input$initialisation$store}"))
}