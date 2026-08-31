#' Add a Session Object as a Pipeline Target
#'
#' @description
#' Snapshots an object from the current R session onto the pipeline store and
#' registers it as a single (non-mapped) target. Unlike `tt_initialise()`, the
#' object is not split into iteration units: a list or a Bioconductor object
#' is stored as one value.
#'
#' The value is written to disk immediately (`qs_save()`). `{targets}` then
#' tracks that file and reads it back when the target runs, so later
#' `tt_single()` / `tt_iterate()` commands can use `target_output` as a
#' dependency. A local variable mentioned only in `command` is not brought
#' in; use this function for that.
#'
#' If `target_output` is omitted, the name of `x` is used
#' (`tt_data(pipeline, airway)` registers `"airway"`), or the left-hand
#' side of an assignment (`tt_data(pipeline, airway <- se)`).
#'
#' For a list of units to map over (for example each row of a parameter grid),
#' use [tt_data_list()] instead.
#'
#' @param tt_input A `tidytargets` object from `tt_initialise()`.
#' @param x Object in the current session to snapshot into the store.
#' @param target_output Character name of the target. `NULL` (the default) uses
#'   the symbol supplied as `x`, or the left-hand side of `x <- value`.
#' @return The updated `tidytargets` object.
#'
#' @examples
#' \dontrun{
#' pipeline <- tt_initialise(store = "store") |>
#'   tt_data(airway, target_output = "airway")
#' }
#' @name tt_data
#' @export
tt_data <- function(tt_input, x, target_output = NULL) {
  UseMethod("tt_data")
}

#' @rdname tt_data
#' @export
tt_data.default <- function(tt_input, x, target_output = NULL) {
  stop_if_not_tidytargets()
}

#' @rdname tt_data
#' @export
tt_data.tidytargets <- function(tt_input, x, target_output = NULL) {
  command <- substitute(x)
  resolved <- parse_command(command, target_output)
  command <- resolved$command
  target_output <- resolved$target_output
  rm(resolved)

  store <- tt_input$initialisation$store
  qs_path <- file.path(store, paste0(target_output, "_data.qs"))
  qs2::qs_save(eval(command, parent.frame()), qs_path)

  file_target <- paste0(target_output, "_file")
  target_script <- paste0(store, ".R")
  read_cmd <- substitute(qs_read(fts), list(fts = as.name(file_target)))

  tar_append(
    fx = quote(tt_factory),
    command = wrap_quote(qs_path),
    target_output = file_target,
    script = target_script,
    format = "file"
  )
  tt_input <- append_step(
    tt_input,
    file_target,
    list(command = qs_path, iterate = "none")
  )

  tar_append(
    fx = quote(tt_factory),
    command = wrap_quote(read_cmd),
    target_output = target_output,
    script = target_script,
    deployment = "main"
  )
  append_step(
    tt_input,
    target_output,
    list(command = read_cmd, iterate = "none")
  )
}

#' Add a List of Units as a Mapped Pipeline Target
#'
#' @description
#' Snapshots a list from the current R session onto the store and registers it
#' as a **mapped** target, one iteration unit per element. This is the mapped
#' analogue of passing a named list to [tt_initialise()]: later
#' [tt_iterate()] steps that mention `target_output` are mapped over the
#' elements.
#'
#' When a later [tt_iterate()] command mentions more than one mapped target,
#' `{targets}` `map()` is used by default. Length-1 lists are omitted from
#' `map()` and do not decide whether sizes match. Different lengths error;
#' pass `pattern = "cross"` for a product of branches.
#'
#' Typical use is a parameter grid split into rows, e.g.
#' `tt_data_list(settings <- grid |> group_split(row_number()))`.
#' Unnamed lists are named with integer indices, the same way
#' [tt_initialise()] names unnamed inputs.
#'
#' If `target_output` is omitted, the name of `x` is used, or the left-hand
#' side of an assignment (`tt_data_list(settings <- rows)`). An inline
#' expression such as `grid |> group_split(row_number())` is not a name, so
#' name it with `<-` or pass `target_output`.
#'
#' @param tt_input A `tidytargets` object from `tt_initialise()`.
#' @param x A list (or list-like object, such as the result of
#'   `dplyr::group_split()`). Each element becomes one mapped unit.
#' @param target_output Character name of the mapped target. `NULL` (the
#'   default) uses the symbol supplied as `x`, or the left-hand side of
#'   `x <- value`.
#' @return The updated `tidytargets` object.
#'
#' @examples
#' \dontrun{
#' grid <- expand.grid(alpha = c(0, 1), lambda = c(0.1, 1))
#' pipeline <- tt_initialise(store = "store") |>
#'   tt_data_list(settings <- grid |> group_split(row_number()))
#' }
#' @name tt_data_list
#' @export
tt_data_list <- function(tt_input, x, target_output = NULL) {
  UseMethod("tt_data_list")
}

#' @rdname tt_data_list
#' @export
tt_data_list.default <- function(tt_input, x, target_output = NULL) {
  stop_if_not_tidytargets()
}

#' @rdname tt_data_list
#' @importFrom purrr set_names
#' @export
tt_data_list.tidytargets <- function(tt_input, x, target_output = NULL) {
  command <- substitute(x)
  resolved <- parse_command(command, target_output)
  command <- resolved$command
  target_output <- resolved$target_output
  rm(resolved)

  x <- eval(command, parent.frame())

  if (!is.list(x)) {
    stop(
      "tidytargets says: tt_data_list() expects a list, ",
      "e.g. grid |> group_split(row_number()).",
      call. = FALSE
    )
  }

  x <- as.list(x)
  nm <- names(x)
  if (is.null(nm) || all(!nzchar(nm))) {
    x <- x |> set_names(seq_len(length(x)))
  }

  store <- tt_input$initialisation$store
  qs_path <- file.path(store, paste0(target_output, "_data.qs"))
  qs2::qs_save(x, qs_path)

  file_target <- paste0(target_output, "_file")
  target_script <- paste0(store, ".R")
  read_cmd <- substitute(qs_read(fts), list(fts = as.name(file_target)))

  tar_append(
    fx = quote(tt_factory),
    command = wrap_quote(qs_path),
    target_output = file_target,
    script = target_script,
    format = "file"
  )
  tt_input <- append_step(
    tt_input,
    file_target,
    list(command = qs_path, iterate = "none")
  )

  tar_append(
    fx = quote(tt_factory),
    command = wrap_quote(read_cmd),
    target_output = target_output,
    script = target_script,
    deployment = "main"
  )
  append_step(
    tt_input,
    target_output,
    list(
      command = read_cmd,
      iterate = "map",
      n_units = length(x)
    )
  )
}
