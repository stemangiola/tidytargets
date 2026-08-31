
#' Execute the tidytargets Pipeline
#'
#' @description
#' Closes the pipeline target list and calls `targets::tar_make()` to execute
#' all queued steps. Returns the `tar_meta()` table.
#'
#' If a target fails with an S4 method-dispatch error on a `list` (typically
#' because a list was brought in with [tt_data()] instead of
#' [tt_data_list()]), the error is rethrown with a hint to use
#' `tt_data_list()`. If `{targets}` errors because `map()` inputs have
#' unequal lengths, the error is rethrown with a hint to use
#' `pattern = "cross"` (or `tt_data()` for a length-1 constant).
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
  
  tryCatch(
    tar_make(
      callr_function = my_callr_function,
      script = script,
      store = tt_input$initialisation$store,
      reporter = tt_input$initialisation$verbosity
    ),
    error = function(e) {

      # Capture the error message and check if it's an S4 dispatch error on a list
      # It is likely due to a list being imported with tt_data() instead of tt_data_list()
      msg <- conditionMessage(e)
      if (
        grepl("unable to find an inherited method", msg, fixed = TRUE) &&
        grepl('= "list"', msg, fixed = TRUE)
      ) {
        stop(
          msg, "\n",
          "tidytargets says: did you remember to use tt_data_list for your list inputs you want to iterate on?",
          call. = FALSE
        )
      }
      if (grepl("unequal lengths of vars in map", msg, fixed = TRUE)) {
        stop(
          msg, "\n",
          "tidytargets says: `pattern = \"map\"` can only be applied with input of the same length (size-1 inputs are fine). Did you mean to use `pattern = \"cross\"` to execute your command over the combinations of your inputs?",
          call. = FALSE
        )
      }
      stop(e)
    }
  )
  
  tar_meta(store = glue("{tt_input$initialisation$store}"))
}