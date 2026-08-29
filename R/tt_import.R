#' Resolve a target name for tt_import / tt_import_list
#'
#' @noRd
resolve_import_target_output <- function(target_output, expr, example) {
  if (is.null(target_output)) {
    if (!is.symbol(expr)) {
      stop(
        "tidytargets says: please supply target_output as a string, ",
        "e.g. ", example, ".",
        call. = FALSE
      )
    }
    target_output <- as.character(expr)
  }

  if (length(target_output) != 1L || !is.character(target_output) ||
      !nzchar(target_output)) {
    stop(
      "tidytargets says: target_output must be a non-empty string.",
      call. = FALSE
    )
  }

  target_output
}

#' Snapshot a session value as a file-tracked pipeline target
#'
#' @noRd
snapshot_import <- function(tt_input, x, target_output, iterate) {
  store <- tt_input$initialisation$store
  qs_path <- file.path(store, paste0(target_output, "_import.qs"))
  qs2::qs_save(x, qs_path)

  file_target <- paste0(target_output, "_file")

  eval(substitute(
    tt_input |>
      tt_single(qp, ft, format = "file") |>
      tt_single(
        command = qs_read(fts),
        target_output = to,
        deployment = "main",
        iterate = it
      ),
    list(
      ft = file_target,
      qp = qs_path,
      to = target_output,
      fts = as.name(file_target),
      it = iterate
    )
  ))
}

#' Import a Session Object as a Pipeline Target
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
#' dependency. A local variable mentioned only in `command` is not imported;
#' use this function for that.
#'
#' If `target_output` is omitted, the name of `x` is used
#' (`tt_import(pipeline, airway)` registers `"airway"`).
#'
#' For a list of units to map over (for example each row of a parameter grid),
#' use [tt_import_list()] instead.
#'
#' @param tt_input A `tidytargets` object from `tt_initialise()`.
#' @param x Object in the current session to snapshot into the store.
#' @param target_output Character name of the target. `NULL` (the default) uses
#'   the symbol supplied as `x`.
#' @return The updated `tidytargets` object.
#'
#' @examples
#' \dontrun{
#' pipeline <- tt_initialise(store = "store") |>
#'   tt_import(airway, target_output = "airway")
#' }
#' @name tt_import
#' @export
tt_import <- function(tt_input, x, target_output = NULL) {
  UseMethod("tt_import")
}

#' @rdname tt_import
#' @export
tt_import.default <- function(tt_input, x, target_output = NULL) {
  stop_if_not_tidytargets()
}

#' @rdname tt_import
#' @export
tt_import.tidytargets <- function(tt_input, x, target_output = NULL) {
  target_output <- resolve_import_target_output(
    target_output,
    substitute(x),
    "tt_import(pipeline, obj, target_output = \"airway\")"
  )
  snapshot_import(tt_input, x, target_output, iterate = "none")
}

#' Import a List of Units as a Mapped Pipeline Target
#'
#' @description
#' Snapshots a list from the current R session onto the store and registers it
#' as a **mapped** target, one iteration unit per element. This is the import
#' analogue of passing a named list to [tt_initialise()]: later
#' [tt_iterate()] steps that mention `target_output` are mapped over the
#' elements.
#'
#' Typical use is a parameter grid split into rows, e.g.
#' `tt_import_list(pipeline, grid |> split(seq_len(nrow(grid))), target_output = "settings")`
#' or `dplyr::group_split()`. Unnamed lists are named with integer indices,
#' the same way [tt_initialise()] names unnamed inputs.
#'
#' If `target_output` is omitted, the name of `x` is used. An inline
#' expression such as `grid |> group_split(row_number())` is not a name, so
#' `target_output` must be supplied.
#'
#' @param tt_input A `tidytargets` object from `tt_initialise()`.
#' @param x A list (or list-like object, such as the result of
#'   `dplyr::group_split()`). Each element becomes one mapped unit.
#' @param target_output Character name of the mapped target. `NULL` (the
#'   default) uses the symbol supplied as `x`.
#' @return The updated `tidytargets` object.
#'
#' @examples
#' \dontrun{
#' grid <- expand.grid(alpha = c(0, 1), lambda = c(0.1, 1))
#' pipeline <- tt_initialise(store = "store") |>
#'   tt_import_list(
#'     grid |> split(seq_len(nrow(grid))),
#'     target_output = "settings"
#'   )
#' }
#' @name tt_import_list
#' @export
tt_import_list <- function(tt_input, x, target_output = NULL) {
  UseMethod("tt_import_list")
}

#' @rdname tt_import_list
#' @export
tt_import_list.default <- function(tt_input, x, target_output = NULL) {
  stop_if_not_tidytargets()
}

#' @rdname tt_import_list
#' @importFrom purrr set_names
#' @export
tt_import_list.tidytargets <- function(tt_input, x, target_output = NULL) {
  target_output <- resolve_import_target_output(
    target_output,
    substitute(x),
    "tt_import_list(pipeline, rows, target_output = \"settings\")"
  )

  if (!is.list(x)) {
    stop(
      "tidytargets says: tt_import_list() expects a list, ",
      "e.g. grid |> split(seq_len(nrow(grid))).",
      call. = FALSE
    )
  }

  x <- as.list(x)
  nm <- names(x)
  if (is.null(nm) || all(!nzchar(nm))) {
    x <- x |> set_names(seq_len(length(x)))
  }

  snapshot_import(tt_input, x, target_output, iterate = "map")
}
