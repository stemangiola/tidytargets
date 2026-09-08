#' Construct a tidytargets pipeline object
#'
#' Four slots, not a flat list of targets: `$initialisation` holds constructor
#' arguments, `$metadata` the free-form store, `$targets` the named step
#' records, `$globals` the named [tt_global()] declarations. Grammar verbs grow
#' `$targets` with `append_step()` so `c()` never strips the class.
#'
#' `$targets` and `$globals` are both keyed by name, so redefining either
#' replaces it rather than adding a second copy to `{store}.R`.
#'
#' @param initialisation Named list of [tt_initialise()] arguments.
#' @param metadata Named list of free-form metadata.
#' @param targets Named list of step records, one per target.
#' @param globals Named list of deparsed global assignments, one per name.
#' @return A `tidytargets` object.
#' @noRd
new_tidytargets <- function(initialisation = list(),
                            metadata = list(),
                            targets = list(),
                            globals = list()) {
  if (length(targets) == 0L) {
    targets <- stats::setNames(list(), character())
  }
  if (length(globals) == 0L) {
    globals <- stats::setNames(list(), character())
  }
  obj <- list(
    initialisation = initialisation,
    metadata = metadata,
    targets = targets,
    globals = globals
  )
  class(obj) <- c("tidytargets", "list")
  schedule_pipeline_ready_notice(initialisation$store)
  obj
}

#' Initialise a tidytargets Pipeline
#'
#' @description
#' Sets up a `targets` pipeline. Saves configuration (and optional mapped
#' inputs) to disk, then returns a `tidytargets` object that downstream
#' grammar functions (e.g. `tt_data()`, `tt_iterate()`, `tt_single()`) can
#' extend before the pipeline is executed with `tt_evaluate()`.
#'
#' `{store}.R` is written from the object by [tt_evaluate()] (or
#' [show_targets_script()]), not as steps are added, so the script always
#' matches the object and redefining a step replaces it. The graph is not run
#' until you print the object or call [tt_evaluate()]. Assigning it does not;
#' an interactive session then says the pipeline is ready to be evaluated,
#' rather than appearing to do nothing.
#'
#' @param tt_input Named vector of inputs, typically file paths, or a named
#'   list of in-memory objects, one element per unit of iteration (e.g. sample).
#'   If names are not set, integer indices are used. `NULL` (the default)
#'   registers no input targets; add objects later with [tt_data()] or pass a
#'   list here to map over.
#' @param store Directory path where pipeline files and targets store are written.
#'   `NULL` (the default) writes to `./tidytargets-<HASH>` in the working
#'   directory and prints that path.
#' @param computing_resources A controller object accepted by
#'   `targets::tar_option_set(controller = )`, such as a `crew` controller or
#'   controller group. `NULL` (the default) runs the pipeline sequentially.
#'   tidytargets does not depend on any compute backend; pass whatever your
#'   deployment uses. Pass a controller group (for example from
#'   [tt_controller_elastic_slurm()]) to make several named tiers available,
#'   and pin a step to one of them with
#'   `resources = tar_resources(crew = tar_resources_crew(controller = "name"))`.
#'   Steps with no `resources` use the first controller in the group.
#' @param debug_step Character name of a single target to debug; passed to
#'   `targets::tar_option_set(debug = ...)`. `NULL` disables debugging.
#' @param verbosity Reporter string passed to `targets::tar_make()`. Defaults to
#'   the current targets configuration value.
#' @param error Error-handling strategy passed to `targets::tar_option_set()`.
#'   Default: `"continue"` (keep running other targets after a failure).
#'   Use `"stop"` to halt the pipeline on the first error.
#' @param update Cue mode string for `targets::tar_cue()`, controlling when
#'   targets are re-run. Default: `"thorough"`.
#' @param garbage_collection Numeric interval (in targets) at which R garbage
#'   collection is triggered during the pipeline run. Default: `0` (disabled).
#' @param workspace_on_error Logical; if `TRUE`, saves a workspace snapshot when
#'   a target errors. Default: `FALSE`.
#' @param packages Character vector of R packages loaded on workers, written to
#'   `tar_option_set(packages = )`. The default is packages currently attached in
#'   the session ([`.packages()`]), as names only — not objects in the global
#'   environment. Pass a character vector to override. `"qs2"` is always
#'   included. The names written to workers are messaged so you can see what
#'   HPC nodes will need to have installed.
#' @param target_output Character name of the mapped input target. Default:
#'   `"input_list"`. Ignored when `tt_input` is `NULL`. A companion
#'   file-tracking target is registered as `{target_output}_file`.
#' @return A `tidytargets` S3 object with `$initialisation` (constructor
#'   arguments), `$metadata` (see [tt_metadata()]), and `$targets` (named
#'   step records), ready to be extended with pipeline step functions. The
#'   graph is not run until you print it or call [tt_evaluate()].
#'
#' @importFrom glue glue
#' @importFrom qs2 qs_save qs_read
#' @importFrom targets tar_script
#' @importFrom purrr set_names
#' @import tarchetypes
#' @import targets
#' @export
tt_initialise <- function(tt_input = NULL,
                           store = NULL,
                           computing_resources = NULL,
                           debug_step = NULL,
                           verbosity = targets::tar_config_get("reporter_make"),
                           error = "continue",
                           update = "thorough",
                           garbage_collection = 0,
                           workspace_on_error = FALSE,
                           packages = attached_packages(),
                           target_output = "input_list"
                          ) {
  
  # Capture all arguments including defaults
  args_list <- as.list(environment())

  has_input <- !is.null(tt_input)

  # if simple names are not set, use integers
  if (has_input && is.null(names(tt_input)))
    tt_input = tt_input |> set_names(seq_len(length(tt_input)))
  

  # Optionally, you can evaluate the arguments if they are expressions
  args_list <- lapply(args_list, eval, envir = parent.frame())
  
  # Write targets. Resolve store so later evaluate/print still finds `{store}.R`
  # if the working directory has changed.
  if (is.null(store)) {
    store <- paste0("./", basename(tempfile(pattern = "tidytargets-")))
    message("tidytargets says: the store is ", store)
  }
  dir.create(store, showWarnings = FALSE, recursive = TRUE)
  store <- normalizePath(store, winslash = "/", mustWork = TRUE)
  args_list$store <- store
  
  # Snapshot the controller now, while it is untouched: crew controllers are
  # mutable, and the script reads this file back rather than deparsing one.
  # A controller group is stored as its controllers and reassembled by the
  # script, because the group itself cannot be restored: it holds condition
  # variables that do not survive serialisation.
  # Mapped inputs (if any) stay with the store too, so tar_make cannot pick
  # up a leftover input_file.qs from another pipeline.
  snapshot <- computing_resources
  if (is_controller_group(snapshot)) snapshot <- snapshot$controllers
  snapshot |> qs_save(file.path(store, "temp_computing_resources.qs"))

  args_list$packages <- unique(c(packages, "qs2"))
  message(
    "tidytargets says: these packages from the session will be loaded on workers: ",
    paste(args_list$packages, collapse = ", ")
  )

  if (has_input) {
    input_qs <- file.path(store, "input_file.qs")
    sample_names_qs <- file.path(store, "sample_names.qs")
    tt_input |> as.list() |> qs_save(input_qs)
    tt_input |> names() |> qs_save(sample_names_qs)
  }
  
  pipe <- new_tidytargets(args_list)

  if (!has_input) return(pipe)

  pipe <- append_step(
    pipe,
    "sample_names_file",
    list(
      command = sample_names_qs,
      iterate = "none",
      factory = factory_call(
        quote(tt_factory),
        list(
          command = wrap_quote(sample_names_qs),
          target_output = "sample_names_file",
          format = "file"
        )
      )
    )
  )

  pipe <- append_step(
    pipe,
    "sample_names",
    list(
      command = quote(qs_read(sample_names_file)),
      iterate = "map",
      factory = factory_call(
        quote(tt_factory),
        list(
          command = wrap_quote(quote(qs_read(sample_names_file))),
          target_output = "sample_names",
          deployment = "main"
        )
      )
    )
  )

  input_file_target <- paste0(target_output, "_file")
  input_read <- substitute(qs_read(ifs), list(ifs = as.name(input_file_target)))

  pipe <- append_step(
    pipe,
    input_file_target,
    list(
      command = input_qs,
      iterate = "none",
      factory = factory_call(
        quote(tt_factory),
        list(
          command = wrap_quote(input_qs),
          target_output = input_file_target,
          format = "file"
        )
      )
    )
  )

  append_step(
    pipe,
    target_output,
    list(
      command = input_read,
      iterate = "map",
      factory = factory_call(
        quote(tt_factory),
        list(
          command = wrap_quote(input_read),
          target_output = target_output,
          deployment = "main"
        )
      )
    )
  )
}


#' Is this a crew controller group?
#'
#' Groups get special treatment on the way into `{store}.R`: only the
#' controllers can be serialised, so the group is rebuilt from them. Tested by
#' class name rather than with `crew::`, since tidytargets does not depend on
#' any compute backend.
#'
#' @param x A controller, controller group, or `NULL`.
#' @return `TRUE` for a controller group.
#' @noRd
is_controller_group <- function(x) {
  inherits(x, "crew_class_controller_group")
}

#' Infer the package that defines a controller-like object
#'
#' Used so the generated pipeline can `library()` the backend that produced
#' `computing_resources` without tidytargets depending on that backend.
#'
#' @param x A controller, controller group, or a plain list of those objects.
#' @return A character vector of package names (possibly empty).
#' @noRd
package_of_object <- function(x) {
  if (is.null(x)) return(character())

  # Recurse into a plain list of controllers, but not S3/S4/R6 objects
  if (is.list(x) && !is.object(x)) {
    return(unique(unlist(lapply(x, package_of_object), use.names = FALSE)))
  }

  pkgs <- character()

  pkg_attr <- attr(class(x), "package")
  if (!is.null(pkg_attr) && !pkg_attr %in% c(".GlobalEnv", "base")) {
    pkgs <- c(pkgs, pkg_attr)
  }

  if (is.function(x$initialize)) {
    pkg <- utils::packageName(environment(x$initialize))
    if (!is.null(pkg)) pkgs <- c(pkgs, pkg)
  }

  unique(pkgs)
}