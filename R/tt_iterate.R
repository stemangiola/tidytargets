#' Add HPC step to pipeline
#'
#' This function adds a new step to the HPC pipeline by appending the appropriate
#' targets to the target script. It allows the user to specify the input and output
#' targets, as well as a custom user function to be applied.
#'
#' @param tt_input A `tidytargets` object.
#' @param command An unevaluated expression. Write `name <- expr` to name the
#'   target from the assignment (`tt_iterate(fit <- lm(y ~ x))`). `{targets}`
#'   tracks dependencies from global symbols in the command (the right-hand
#'   side if you used `<-`), using the same static analysis as `{targets}`
#'   (`$column` is not a dependency). Mapped targets referenced here also set the
#'   iteration pattern. `=` inside the call is argument matching, not
#'   assignment; use `<-`.
#' @param target_output Character name of the output target. Optional if
#'   `command` is `name <- expr`.
#' @param user_function_source_path Optional character path to an R script that
#'   should be sourced in the worker before evaluating `command`. `NULL`
#'   sources nothing.
#' @param pattern `"map"` (the default) or `"cross"`. `"map"` pairs mapped
#'   inputs; `{targets}` errors at make time if their lengths differ.
#'   Pass `"cross"` for a product of branches. A single mapped input is
#'   always `map()`. With two or more mapped inputs, the chosen pattern
#'   is messaged; `cross()` names the targets being crossed.
#' @param ... Additional factory arguments such as `format`, `deployment`,
#'   or `packages`.
#'
#' @export
tt_iterate <- function(
    tt_input,
    command = NULL,
    target_output = NULL,
    user_function_source_path = NULL,
    pattern = c("map", "cross"),
    ...
) {
  UseMethod("tt_iterate")
}

#' @rdname tt_iterate
#' @export
tt_iterate.default <- function(
    tt_input,
    command = NULL,
    target_output = NULL,
    user_function_source_path = NULL,
    pattern = c("map", "cross"),
    ...
) {
  stop_if_not_tidytargets()
}

#' @rdname tt_iterate
#' @importFrom glue glue
#' @export
tt_iterate.tidytargets <- function(
    tt_input,
    command = NULL,
    target_output = NULL,
    user_function_source_path = NULL,
    pattern = c("map", "cross"),
    ...
) {
    
    command <- substitute(command)
    resolved <- parse_command(command, target_output)
    command <- resolved$command
    target_output <- resolved$target_output
    rm(resolved)
    
    # Target script
    target_script = glue("{tt_input$initialisation$store}.R")
    
    # Append source if any
    write_source(user_function_source_path, target_script)

    mapped <- mapped_names_in_command(command, tt_input, "map")
    spec <- resolve_pattern(mapped, pattern)
    pattern_type <- spec$pattern_type
    pattern_names <- spec$pattern_names
    rm(spec)

    tar_append(
      fx = tt_factory |> quote(),
      command = wrap_quote(command),
      target_output = target_output,
      script = target_script,
      other_arguments_to_map = pattern_names,
      pattern_type = pattern_type,
      ...
    )
  
      
    append_step(
      tt_input,
      target_output,
      list(command = command, iterate = "map")
    )
    
    
  }


#' Choose map() or cross() from mapped names in the command
#'
#' All `iterate = "map"` names go into the pattern. `{targets}` checks
#' equal lengths at make time. `cross()` needs two or more names; a
#' single mapped input is always `map()`.
#'
#' @param mapped Character names of mapped inputs.
#' @param pattern `"map"` or `"cross"`.
#' @return A list with `pattern_type` and `pattern_names`.
#' @noRd
resolve_pattern <- function(mapped, pattern = c("map", "cross")) {
  pattern <- match.arg(pattern)
  mapped <- unname(mapped)
  if (is.null(mapped)) mapped <- character()

  use_cross <- identical(pattern, "cross") && length(mapped) >= 2L
  pattern_type <- if (use_cross) "cross" else "map"

  if (use_cross) {
    message(
      "tidytargets says: crossing ",
      paste(mapped, collapse = ", "),
      sep = ""
    )
  } else if (length(mapped) >= 2L) {
    message("tidytargets says: using map()")
  }

  list(pattern_type = pattern_type, pattern_names = mapped)
}

#' Pipeline steps a command mentions, filtered by iterate mode
#'
#' Uses [targets::tar_deps_raw()] so `$column` and similar extractors are
#' not treated as dependencies (`formula_df$formula` depends on
#' `formula_df`, not a target named `formula`). Then keeps names that are
#' already steps in `tt_input$targets` whose `$iterate` is in `value`.
#'
#' `tt_iterate()` uses this with `value = "map"` to find mapped stems in the
#' command (from `tt_data_list()`, [tt_split()], a mapped `tt_initialise()`
#' input, or a prior iterate). Those names drive `map()` / `cross()`. Symbols that are
#' not pipeline steps (functions, locals) and unmapped steps (`iterate =
#' "none"`) are ignored.
#'
#' @param command A language object. Anything else returns `character()`.
#' @param tt_input A `tidytargets` object.
#' @param value `$iterate` value(s) to keep, typically `"map"`.
#' @return Character names of matching steps, in `{targets}` dependency order.
#' @noRd
mapped_names_in_command <- function(command, tt_input, value) {
  if (!is.language(command)) return(character())

  vars <- targets::tar_deps_raw(command)
  vars <- vars[vars %in% names(tt_input$targets)]

  Filter(
    function(v) isTRUE(tt_input$targets[[v]]$iterate %in% value),
    vars
  )
}
