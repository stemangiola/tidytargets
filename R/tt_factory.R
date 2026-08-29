#' Internal Factory for Iterating Targets
#'
#' @description
#' Low-level factory that builds a `tar_target_raw()` call for the
#' tidytargets pipeline. Not intended to be called by end users directly.
#'
#' @param command An unevaluated expression passed to `tar_target_raw()`.
#'   `{targets}` tracks dependencies from symbols in this expression.
#' @param target_output Character name of the output target.
#' @param other_arguments_to_map Character vector of target names that should
#'   be mapped over.
#' @param packages Character vector of R packages to load in the worker.
#' @param deployment Deployment strategy string (e.g. `"worker"` or `"main"`).
#' @param format Storage format string for the target value.
#' @param ... Unused; retained so extra factory arguments are ignored.
#' @return A `tar_target` object.
#' @export
tt_factory = function(
    command,
    target_output, 
    other_arguments_to_map = c(), 
    packages = targets::tar_option_get("packages") , 
    deployment = targets::tar_option_get("deployment"),
    format = targets::tar_option_get("format"),
    ...
){
  
  tar_target_raw(
    name = target_output |> as.character(), 
    command = command,
    pattern = build_pattern(other_arguments_to_map = other_arguments_to_map),
    iteration = "list", 
    packages = packages,
    deployment = deployment,
    format = format
  )
   
}
