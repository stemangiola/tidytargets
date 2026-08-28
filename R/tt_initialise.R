#' Initialise a tidytargets Pipeline
#'
#' @description
#' Sets up and writes a `targets` pipeline script. Saves inputs and
#' configuration to disk, then returns a `tidytargets` object that downstream
#' grammar functions (e.g. `tt_iterate()`, `tt_single()`, `tt_evaluate()`)
#' can extend before the pipeline is executed with `tt_evaluate()`. The graph
#' is not run until you print the object or call [tt_evaluate()]. Assigning
#' it does not; an interactive session then says the pipeline is ready to be
#' evaluated, rather than appearing to do nothing.
#'
#' @param tt_input Named vector of inputs, typically file paths, or a named
#'   list of in-memory objects, one element per unit of iteration (e.g. sample).
#'   If names are not set, integer indices are used.
#' @param store Directory path where pipeline files and targets store are written.
#'   `NULL` (the default) writes to `./tidytargets-<HASH>` in the working
#'   directory and prints that path.
#' @param computing_resources A controller object accepted by
#'   `targets::tar_option_set(controller = )`, such as a `crew` controller or
#'   controller group. `NULL` (the default) runs the pipeline sequentially.
#'   tidytargets does not depend on any compute backend; pass whatever your
#'   deployment uses.
#' @param debug_step Character name of a single target to debug; passed to
#'   `targets::tar_option_set(debug = ...)`. `NULL` disables debugging.
#' @param verbosity Reporter string passed to `targets::tar_make()`. Defaults to
#'   the current targets configuration value.
#' @param error Error-handling strategy passed to `targets::tar_option_set()`.
#'   `NULL` uses the targets default.
#' @param update Cue mode string for `targets::tar_cue()`, controlling when
#'   targets are re-run. Default: `"thorough"`.
#' @param garbage_collection Numeric interval (in targets) at which R garbage
#'   collection is triggered during the pipeline run. Default: `0` (disabled).
#' @param workspace_on_error Logical; if `TRUE`, saves a workspace snapshot when
#'   a target errors. Default: `FALSE`.
#' @param packages Character vector of R packages loaded on workers. Defaults to
#'   `"tidytargets"`.
#' @param target_output Character name of the mapped input target. Default:
#'   `"input_list"`. A companion file-tracking target is registered as
#'   `{target_output}_file`.
#' @return A `tidytargets` S3 object containing the initialisation arguments in
#'   `$initialisation` and an empty metadata store (see `tt_metadata()`), ready
#'   to be extended with pipeline step functions. The graph is not run until
#'   you print it or call [tt_evaluate()].
#'
#' @importFrom glue glue
#' @importFrom qs2 qs_save qs_read
#' @importFrom targets tar_script
#' @importFrom purrr set_names
#' @import tarchetypes
#' @import targets
#' @export
tt_initialise <- function(tt_input,
                           store = NULL,
                           computing_resources = NULL,
                           debug_step = NULL,
                           verbosity = targets::tar_config_get("reporter_make"),
                           error = NULL,
                           update = "thorough",
                           garbage_collection = 0,
                           workspace_on_error = FALSE,
                           packages = "tidytargets",
                           target_output = "input_list"
                          ) {
  
  # Capture all arguments including defaults
  args_list <- as.list(environment())
  
  # if simple names are not set, use integers
  if(tt_input |> names() |> is.null())
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
  
  # Keep inputs with the store so tar_make cannot pick up a leftover
  # input_file.qs from another pipeline in the working directory.
  input_qs <- file.path(store, "input_file.qs")
  sample_names_qs <- file.path(store, "sample_names.qs")
  resources_qs <- file.path(store, "temp_computing_resources.qs")

  tt_input |> as.list() |> qs_save(input_qs)
  tt_input |> names() |> qs_save(sample_names_qs)
  computing_resources |> qs_save(resources_qs)
  backend_packages <- package_of_object(computing_resources)
  
  # Write pipeline to a file
  {
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
      controller = qs_read(rf),
      format = "qs",
      packages = p,
      trust_timestamps = TRUE, 
      workspace_on_error = w
    )
     
    target_list <- list()
    
    } |> 
    substitute(env = list(
      d = debug_step, e = error, u = update, g = garbage_collection,
      w = workspace_on_error, p = unique(c(packages, "qs2")),
      bp = backend_packages, rf = resources_qs
    )) |> 
    tar_script_append2(script = glue("{store}.R"), append = FALSE)

  
  tt_input = 
    list(initialisation = args_list, .metadata = list() ) |>

    add_class("tidytargets")

  input_file_target <- paste0(target_output, "_file")

  eval(substitute(
    tt_input |>

      # Sample names
      tt_single("sample_names_file", snf, format = "file") |>

      tt_single(
        target_output = "sample_names",
        command = qs_read(sample_names_file),
        deployment = "main",
        iterate = "map"
      ) |>

      # Files
      tt_single(ift, iff, format = "file") |>

      tt_single(
        target_output = to,
        command = qs_read(ifs),
        deployment = "main",
        iterate = "map"
      ),
    list(
      ift = input_file_target,
      to = target_output,
      ifs = as.name(input_file_target),
      snf = sample_names_qs,
      iff = input_qs
    )
  ))
}
