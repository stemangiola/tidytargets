

#' Append a named step without dropping the tidytargets class
#'
#' @param pipe A `tidytargets` object.
#' @param name Character target name.
#' @param step Named list of step fields (`command`, `iterate`, …).
#' @return The updated `tidytargets` object.
#' @noRd
append_step <- function(pipe, name, step) {
  pipe$targets[[name]] <- step
  schedule_pipeline_ready_notice(pipe$initialisation$store)
  pipe
}

stop_if_not_tidytargets <- function() {
  stop(
    "tidytargets says: this step expects a tidytargets object from tt_initialise().",
    call. = FALSE
  )
}

# Negation
not = function(is){	!is }

#' Names of packages attached in the current session
#'
#' Character names only — not loaded namespaces, and not objects in
#' `.GlobalEnv`. Default packages that ship with R are omitted; workers
#' already have those.
#'
#' @return A character vector that always includes `"tidytargets"`.
#' @noRd
attached_packages <- function() {
  drop <- unique(c("base", getOption("defaultPackages")))
  unique(c(setdiff(.packages(), drop), "tidytargets"))
}



#' Write the Targets Script Without Running the Pipeline
#'
#' @description
#' `{store}.R` is generated from the pipeline object when the pipeline runs.
#' Call this to write it early, so the `{targets}` functions that read a
#' script can inspect the graph before anything executes, for example
#' `targets::tar_manifest()`, `targets::tar_visnetwork()`,
#' `targets::tar_outdated()`.
#'
#' The pipeline's script and store are registered with
#' `targets::tar_config_set()`, so those functions then need no arguments.
#' That writes `_targets.yaml` in the working directory, which is how
#' `{targets}` is told to use a script other than `_targets.R`.
#'
#' Nothing is executed; use [tt_evaluate()] to run the pipeline.
#'
#' @param pipe A `tidytargets` object from [tt_initialise()].
#'
#' @return The script path, invisibly.
#'
#' @examples
#' \dontrun{
#' pipe <- tt_initialise(store = "store") |> tt_single(n <- 1)
#' tt_script(pipe)
#' targets::tar_manifest()
#' targets::tar_visnetwork()
#' }
#'
#' @importFrom targets tar_config_set
#' @export
tt_script <- function(pipe) {
  if (!inherits(pipe, "tidytargets")) stop_if_not_tidytargets()

  script <- write_script(pipe)
  tar_config_set(script = script, store = pipe$initialisation$store)
  invisible(script)
}

#' Print the Targets Script for a tidytargets Pipeline
#'
#' @description
#' Writes `{store}.R` for a `tidytargets` object and prints its contents with a
#' markdown-style heading. Useful for inspecting the pipeline script while
#' composing steps: the script shown is the one [tt_evaluate()] would run.
#'
#' @param pipe A `tidytargets` object from `tt_initialise()`.
#'
#' @return Invisibly returns the script lines; called for its side effect of
#'   printing.
#'
#' @export
show_targets_script <- function(pipe) {
  path <- write_script(pipe)
  cat("## ", basename(path), "\n\n", sep = "")
  lines <- readLines(path)
  writeLines(lines)
  invisible(lines)
}

build_pattern = function(other_arguments_to_map = c(), pattern_type = "map"){

  if(other_arguments_to_map |> length() == 0) return(NULL)

  fn <- if (identical(pattern_type, "cross")) as.name("cross") else as.name("map")
  as.call(c(fn, other_arguments_to_map |> lapply(as.name)))

}
