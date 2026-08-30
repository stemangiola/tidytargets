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
#'   side if you used `<-`). Mapped targets referenced here also set the
#'   iteration pattern. `=` inside the call is argument matching, not
#'   assignment; use `<-`.
#' @param target_output Character name of the output target. Optional if
#'   `command` is `name <- expr`.
#' @param user_function_source_path Optional character path to an R script that
#'   should be sourced in the worker before evaluating `command`. `NULL`
#'   sources nothing.
#' @param pattern `"map"` (the default) or `"cross"`. `"map"` pairs
#'   mapped inputs of equal length and omits length-1 names from the
#'   pattern. Unequal sizes (ignoring length-1 lists) error; pass
#'   `"cross"` for a product of branches. With two or more mapped
#'   inputs, the chosen pattern is messaged; `cross()` names the
#'   targets being crossed.
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
#' @importFrom purrr set_names
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
    sizes <- vapply(mapped, function(n) {
      n_units <- tt_input[[n]]$n_units
      if (is.null(n_units)) NA_integer_ else as.integer(n_units)[[1L]]
    }, integer(1), USE.NAMES = TRUE)
    spec <- process_pattern(sizes, pattern)
    pattern_type <- spec$pattern_type
    pattern_names <- spec$pattern_names
    n_units <- spec$n_units
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
  
      
    # Add pipeline step
    tt_input |>
      c(
        as.list(environment())[-1] |> 
          c(list(iterate = "map", n_units = n_units)) |> 
          list() |> 
          set_names(target_output) 
      ) |>
      add_class("tidytargets")
    
    
  }


#' Process map/cross from mapped branch counts
#'
#' Applies `pattern`: errors if `map` lengths differ (ignoring size 1),
#' omits size-1 names from `map()`, records `n_units`, and messages when
#' there are two or more mapped inputs. `cross()` also names the targets
#' being crossed.
#'
#' @param sizes Named integer vector of `$n_units` for mapped inputs.
#'   Missing sizes are `NA`.
#' @param pattern `"map"` or `"cross"`.
#' @return A list with `pattern_type`, `pattern_names`, and `n_units`.
#' @noRd
process_pattern <- function(sizes, pattern = c("map", "cross")) {
  pattern <- match.arg(pattern)
  mapped <- names(sizes)
  if (is.null(mapped)) mapped <- character()

  # Size 1 must not decide whether lengths match; missing sizes are ignored.
  varying <- unname(sizes[!is.na(sizes) & sizes > 1L])
  # cross() needs two or more names; a single mapped input is always map().
  use_cross <- identical(pattern, "cross") && length(mapped) >= 2L
  pattern_type <- if (use_cross) "cross" else "map"

  if (!use_cross && length(unique(varying)) > 1L) {
    size_txt <- paste(sprintf("%s: %s", names(sizes), sizes), collapse = ", ")
    stop(
      "tidytargets says: mapped sizes ", size_txt,
      " are not equal; use pattern = \"cross\".",
      call. = FALSE
    )
  }

  # {targets} map() requires equal lengths. Length-1 lists are constants, so
  # they stay in the command but not in the pattern. cross() keeps them.
  pattern_names <- mapped
  if (!use_cross) {
    varying_names <- mapped[!is.na(sizes) & sizes > 1L]
    if (length(varying_names) > 0L) pattern_names <- unname(varying_names)
  }

  known <- unname(sizes[!is.na(sizes)])
  n_units <- if (length(known) == 0L) {
    NA_integer_
  } else if (use_cross) {
    as.integer(prod(known))
  } else {
    shared <- known[known > 1L]
    if (length(shared) == 0L) known[[1L]] else shared[[1L]]
  }

  if (use_cross) {
    size_txt <- paste(sprintf("%s: %s", names(sizes), sizes), collapse = ", ")
    message(
      "tidytargets says: crossing ",
      paste(pattern_names, collapse = ", "),
      " (", size_txt, ")",
      sep = ""
    )
  } else if (length(mapped) >= 2L) {
    size_txt <- paste(sprintf("%s: %s", names(sizes), sizes), collapse = ", ")
    message(
      "tidytargets says: mapped sizes ", size_txt, "; using map()",
      sep = ""
    )
  }

  list(
    pattern_type = pattern_type,
    pattern_names = unname(pattern_names),
    n_units = n_units
  )
}

#' Pipeline steps a command mentions, filtered by iterate mode
#'
#' Pulls symbol names out of `command`, keeps those that are already steps
#' in `tt_input`, then keeps only steps whose `$iterate` is in `value`.
#'
#' `tt_iterate()` uses this with `value = "map"` to find mapped stems in the
#' command (from `tt_data_list()`, a mapped `tt_initialise()` input, or a
#' prior iterate). Those names drive `map()` / `cross()`. Symbols that are
#' not pipeline steps (functions, locals) and unmapped steps (`iterate =
#' "none"`) are ignored.
#'
#' @param command A language object. Anything else returns `character()`.
#' @param tt_input A `tidytargets` object.
#' @param value `$iterate` value(s) to keep, typically `"map"`.
#' @return Character names of matching steps, in `all.vars()` order.
#' @noRd
mapped_names_in_command <- function(command, tt_input, value) {
  if (!is.language(command)) return(character())

  vars <- all.vars(command)
  vars <- vars[vars %in% names(tt_input)]

  Filter(
    function(v) isTRUE(tt_input[[v]]$iterate %in% value),
    vars
  )
}