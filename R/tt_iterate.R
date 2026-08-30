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
#' @param pattern `"auto"` (the default) chooses `{targets}` `map()` vs
#'   `cross()` from the lengths of mapped inputs referenced in `command`.
#'   Equal sizes (ignoring length-1 lists) use `map()` and omit length-1
#'   names from the pattern; different sizes use `cross()`. `"map"` or
#'   `"cross"` force a pattern. With two or more mapped inputs, the
#'   chosen pattern is messaged.
#' @param ... Additional factory arguments such as `format`, `deployment`,
#'   or `packages`.
#'
#' @export
tt_iterate <- function(
    tt_input,
    command = NULL,
    target_output = NULL,
    user_function_source_path = NULL,
    pattern = c("auto", "map", "cross"),
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
    pattern = c("auto", "map", "cross"),
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
    pattern = c("auto", "map", "cross"),
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

    # Guess the right iteration strategy
    mapped <- mapped_names_in_command(command, tt_input, "map")
    pattern <- match.arg(pattern)

    sizes <- vapply(mapped, function(n) {
      n_units <- tt_input[[n]]$n_units
      if (is.null(n_units)) NA_integer_ else as.integer(n_units)[[1L]]
    }, integer(1), USE.NAMES = TRUE)
    spec <- infer_iteration_strategy(sizes, pattern)
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


#' Infer map() vs cross() from mapped branch counts
#'
#' Chooses `map()` vs `cross()`, which names go in that pattern, and how many
#' output branches to record. Size 1 does not decide map vs cross. With two
#' or more mapped inputs, the sizes and chosen pattern are messaged.
#'
#' @param sizes Named integer vector of `$n_units` for mapped inputs, in
#'   command order. Missing sizes are `NA`.
#' @param pattern `"auto"`, `"map"`, or `"cross"`.
#' @return A list with `pattern_type`, `pattern_names`, `n_units`, and
#'   `equal`.
#' @noRd
infer_iteration_strategy <- function(sizes, pattern = c("auto", "map", "cross")) {
  pattern <- match.arg(pattern)
  mapped <- names(sizes)
  if (is.null(mapped)) mapped <- character()

  # Size 1 must not decide map vs cross; missing sizes are ignored.
  varying <- unname(sizes[!is.na(sizes) & sizes > 1L])
  equal <- length(varying) <= 1L || length(unique(varying)) == 1L

  auto <- identical(pattern, "auto")
  use_cross <- if (auto) !equal else identical(pattern, "cross")
  # cross() needs two or more names; a single mapped input is always map().
  if (length(mapped) < 2L) use_cross <- FALSE

  # Names that go into map()/cross() in the target script. Start with every
  # mapped input; auto-map may drop some below. Forced map/cross keep all.
  pattern_names <- mapped

  # {targets} map() requires every patterned input to have the same length.
  # A length-1 list is a constant reused on every branch. Putting it in
  # map() would fail unless the other inputs are also length 1, so auto-map
  # omits those names: they stay in the command as ordinary dependencies.
  # Forced pattern = "map" does not drop them (the user asked for that
  # pattern). cross() keeps size-1 names: a 1 x n product is valid.
  if (auto && !use_cross) {
    varying_names <- mapped[!is.na(sizes) & sizes > 1L]
    # If every mapped input is size 1 (or unknown), keep the full set.
    if (length(varying_names) > 0L) pattern_names <- unname(varying_names)
  }

  # Cross is the product of sizes; map is the shared length (or 1).
  known <- unname(sizes[!is.na(sizes)])
  n_units <- if (length(known) == 0L) {
    NA_integer_
  } else if (use_cross) {
    as.integer(prod(known))
  } else {
    shared <- known[known > 1L]
    if (length(shared) == 0L) known[[1L]] else shared[[1L]]
  }

  pattern_type <- if (use_cross) "cross" else "map"

  if (length(mapped) >= 2L) {
    size_txt <- paste(sprintf("%s: %s", names(sizes), sizes), collapse = ", ")
    message(
      "tidytargets says: mapped sizes ", size_txt, "; using ",
      pattern_type, "()",
      sep = ""
    )
  }

  list(
    pattern_type = pattern_type,
    pattern_names = unname(pattern_names),
    n_units = n_units,
    equal = equal
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