#' Build the factory call for one pipeline step
#'
#' Returns `<fx>(...)` unevaluated. [write_script()] deparses it into
#' `{store}.R` when the pipeline runs, so adding a step touches the pipeline
#' object only, never the file.
#'
#' @param fx Quoted factory, typically `quote(tt_factory)`.
#' @param ... Factory arguments (`command`, `target_output`, ...).
#' @return A call object.
#' @noRd
factory_call <- function(fx, ...) {

  # Symbols are wrapped in quote() so they survive into the script as names.
  # Left bare, they would be evaluated in an environment where the targets
  # they refer to do not exist.
  as.call(c(fx, quote_name_classes(list(...))))
}

#' Write the targets script for a pipeline
#'
#' `{store}.R` is derived from the pipeline object rather than accumulated as
#' steps are added: the header comes from `$initialisation`, then the
#' assignments in `$globals`, then one factory call per record in `$targets`.
#' Since both are keyed by name, redefining a step or a global replaces it, and
#' the file always matches the object.
#'
#' `{targets}` `eval()`s the script and takes the last expression as the
#' pipeline, hence the trailing `target_list`.
#'
#' Writing is repeatable: nothing here has a side effect beyond the script
#' itself, so callers that only want to inspect the graph can write it as
#' often as they like.
#'
#' @param pipe A `tidytargets` object.
#' @return The path to the written script.
#' @noRd
write_script <- function(pipe) {
  init <- pipe$initialisation

  # Saved by tt_initialise(), and read back by the script, so a live backend
  # object never has to be deparsed into source. A group is stored as its
  # controllers and assembled here: only the controllers survive being
  # serialised, so restoring the group whole would give the script a set of
  # dead condition variables.
  resources_qs <- file.path(init$store, "temp_computing_resources.qs")
  controller_expr <- substitute(qs_read(rf), list(rf = resources_qs))
  if (is_controller_group(init$computing_resources)) {
    controller_expr <- substitute(
      do.call(crew_controller_group, qs_read(rf)),
      list(rf = resources_qs)
    )
  }

  header <- {
    library(tidytargets)
    do.call("library", list("dplyr"))
    do.call("library", list("magrittr"))
    do.call("library", list("targets"))
    do.call("library", list("tarchetypes"))
    do.call("library", list("qs2"))
    lapply(bp, function(pkg) do.call("library", list(pkg)))

    tar_option_set(
      memory = "transient",
      garbage_collection = g,
      storage = "worker",
      retrieval = "worker",
      error = e,
      debug = d, # Set the target you want to debug.
      cue = tar_cue(mode = u), # Force skip non-debugging outdated targets.
      controller = cx,
      format = "qs",
      packages = p,
      trust_timestamps = TRUE,
      workspace_on_error = w
    )

  } |>
    substitute(env = list(
      d = init$debug_step, e = init$error, u = init$update,
      g = init$garbage_collection, w = init$workspace_on_error,
      p = init$packages, cx = controller_expr,
      bp = package_of_object(init$computing_resources)
    )) |>
    deparse() |>
    head(-1) |>
    tail(-1)

  # Globals are already source, deparsed by tt_global(). They sit above the
  # target list so the script reads as configuration first, then targets, and
  # one assignment per name because $globals is keyed by name.
  globals <- unlist(pipe$globals, use.names = FALSE)

  # Functions a command calls may live in a user script rather than in the
  # pipeline object. Sourcing happens once, above the targets.
  sources <- unique(unlist(lapply(pipe$targets, function(step) step$source)))
  sources <- unlist(lapply(sources, function(path) deparse(call("source", path))))

  factories <- unlist(lapply(pipe$targets, function(step) {
    c(
      "target_list <- target_list |> target_append(",
      deparse(step$factory, width.cutoff = 500),
      ")"
    )
  }))

  script <- paste0(init$store, ".R")
  writeLines(
    c(header, globals, sources, "target_list <- list()", factories, "target_list"),
    script
  )
  script
}

#' Quote elements with class 'name'
#'
#' This function takes a list and returns a new list where any elements
#' with the class 'name' are converted to their quoted equivalent using `quote()`.
#' This is useful for preserving unevaluated expressions in the list.
#'
#' @param lst A list of elements to process.
#' @return A list where elements with class 'name' are quoted.
#' @noRd
quote_name_classes <- function(lst) {
  lapply(lst, function(x) {
    if ("name" %in% class(x)) {
      # Manually create the quoted expression
      as.call(list(as.name("quote"), x))
    } else {
      x  # Leave as is for other elements
    }
  })
}

#' Wrap a language object so it deparses as quote(...)
#'
#' @noRd
wrap_quote <- function(expr) {
  if (is.null(expr) || !is.language(expr)) return(expr)
  as.call(list(as.name("quote"), expr))
}

#' Append Targets to the Pipeline Target List
#'
#' @description
#' Combines an existing list of `tar_target` objects with one or more new
#' targets. The generated pipeline script assigns the result back to
#' `target_list`.
#'
#' @param target_list The existing list of `tar_target` objects to append to.
#' @param ... One or more `tar_target` objects to append.
#' @return The combined list of targets.
#' @export
target_append <- function(target_list, ...) {
  c(target_list, list(...))
}
