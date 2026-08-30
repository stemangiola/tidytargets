#' Add a Report Step to the tidytargets Pipeline
#'
#' @description
#' Appends a Quarto/R Markdown rendering step to the tidytargets pipeline, which
#' generates an HTML report using `tarchetypes::tar_quarto_raw()`.
#'
#' @param tt_input A `tidytargets` object.
#' @param target_output Character name of the output target for the rendered report.
#' @param rmd_path Character path to the `.qmd` or `.Rmd` report file.
#' @param params An unevaluated `list()` of report parameters. `{targets}` tracks
#'   dependencies from symbols in this expression (including upstream target names).
#' @param ... Additional factory arguments such as `deployment` or `packages`.
#'
#' @export
tt_report <- function(tt_input, target_output = NULL, rmd_path = NULL, params = list(), ...) {
  UseMethod("tt_report")
}

#' @rdname tt_report
#' @export
tt_report.default <- function(tt_input, target_output = NULL, rmd_path = NULL, params = list(), ...) {
  stop_if_not_tidytargets()
}

#' @rdname tt_report
#' @importFrom glue glue
#' @importFrom purrr set_names
#' @export
tt_report.tidytargets <- function(tt_input, target_output = NULL, rmd_path = NULL, params = list(), ...) {
    
    params <- substitute(params)

    require_target_output(target_output)
    
    # Target script
    target_script = glue("{tt_input$initialisation$store}.R")
    
    external_dir <- file.path(tt_input$initialisation$store, "external")
    dir.create(external_dir, showWarnings = FALSE, recursive = TRUE)
    external_dir <- normalizePath(external_dir)

    tar_append(
      fx = tt_internal_report |> quote(),
      target_output = target_output,
      script = target_script,
      rmd_path = rmd_path,
      output_file = glue("{external_dir}/{target_output}") |> as.character(),
      render_arguments = wrap_quote(as.call(list(as.name("list"), params = params))),
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

  #' Internal Factory for Report Targets
#'
#' @description
#' Low-level factory that builds `tarchetypes::tar_quarto_raw()` calls for
#' pipeline report targets. Not intended to be called by end users directly.
#'
#' @param target_output Character name of the output target.
#' @param rmd_path Character path to the Quarto (`.qmd`) or R Markdown (`.Rmd`)
#'   report file.
#' @param render_arguments A quoted `list()` of parameters passed to the report
#'   at render time.
#' @param output_file Optional character name for the rendered output file.
#' @param packages Character vector of R packages to load in the worker.
#' @param deployment Deployment strategy string.
#' @param ... Additional named arguments.
#' @return A `tar_target` object.
#' @export
tt_internal_report = function(
    target_output, 
    rmd_path,
    render_arguments = quote(list()),
    output_file = NULL,
    packages = targets::tar_option_get("packages") , 
    deployment = targets::tar_option_get("deployment"),
    ...
){

  tar_quarto_raw(
    name = target_output |> as.character(), 
    path = rmd_path,
    output_file = output_file,
    execute_params = render_arguments,
    packages = packages,
    deployment = deployment
  )

}
