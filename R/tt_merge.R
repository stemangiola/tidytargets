#' Add a Merge Step to the tidytargets Pipeline
#'
#' @description
#' Appends a targets step that collects and merges results from all iterated
#' upstream targets into a single aggregate object.
#'
#' @param tt_input A `tidytargets` object.
#' @param target_output Character name of the output target.
#' @param command An unevaluated expression. `{targets}` tracks dependencies from
#'   global symbols in this expression (including upstream target names).
#' @param user_function_source_path Optional character path to an R script to
#'   source in the worker before evaluating `command`. `NULL` sources nothing.
#' @param ... Additional factory arguments such as `format`, `deployment`,
#'   or `packages`.
#'
#' @export
tt_merge <- function(
    tt_input,
    target_output = NULL,
    command = NULL,
    user_function_source_path = NULL,
    ...
) {
  UseMethod("tt_merge")
}

#' @rdname tt_merge
#' @export
tt_merge.default <- function(
    tt_input,
    target_output = NULL,
    command = NULL,
    user_function_source_path = NULL,
    ...
) {
  stop_if_not_tidytargets()
}

#' @rdname tt_merge
#' @importFrom glue glue
#' @importFrom purrr set_names
#' @export
tt_merge.tidytargets <- function(
    tt_input,
    target_output = NULL,
    command = NULL,
    user_function_source_path = NULL,
    ...
) {
    
    command <- substitute(command)
    
    # Target script
    target_script = glue("{tt_input$initialisation$store}.R")
    
    # Delete line with target in case the user execute the command, without calling tt_initialise
    target_output |>  delete_lines_with_word(target_script)
    
    # Append source if any
    write_source(user_function_source_path, target_script)

    tar_append(
        fx = tt_factory |> quote(),
        target_output = target_output,
        script = target_script,
        command = wrap_quote(command),
        ...
    )

    # Add pipeline step
    tt_input |>
      c(
        as.list(environment())[-1] |> 
          c(list(iterate = "single")) |> 
          list() |> 
          set_names(target_output) 
      ) |>
      add_class("tidytargets")
    
    
  }
