# Helper function to add class to an object
add_class <- function(obj, class_name) {
  class(obj) <- c(class_name, class(obj))
  # Grammar constructors return through here after `c()` drops the class.
  # Scheduling at this single restore point covers initialise, iterate,
  # summarise, merge, and report without each having to remember the notice.
  if (identical(class_name, "tidytargets")) {
    schedule_pipeline_ready_notice(obj$initialisation$store)
  }
  return(obj)
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



#' Print the Targets Script for a tidytargets Pipeline
#'
#' @description
#' Reads `{store}.R` for a `tidytargets` object and prints its contents with a
#' markdown-style heading. Useful for inspecting the pipeline script while
#' composing steps.
#'
#' @param pipe A `tidytargets` object from `tt_initialise()`.
#'
#' @return Invisibly returns the script lines; called for its side effect of
#'   printing.
#'
#' @export
show_targets_script <- function(pipe) {
  path <- paste0(pipe$initialisation$store, ".R")
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
