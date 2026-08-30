#' Get or Set Free-Form Metadata on a tidytargets Object
#'
#' @description
#' Reads and writes the metadata store of a `tidytargets` object, a free-form
#' named list for information that is not part of the pipeline itself, such as
#' API endpoints, credentials handles, dataset identifiers or provenance notes.
#'
#' Called with no additional arguments the metadata list is returned. Called
#' with named arguments the entries are merged into the existing metadata and
#' the `tidytargets` object is returned, so the call can sit anywhere in a
#' pipeline. Passing `NULL` as a value removes that entry.
#'
#' Metadata lives in the pipeline object only; it is not written to the targets
#' script and is not available to workers. To pass values to workers, include
#' them in the `command` expression of `tt_iterate()` or `tt_single()`.
#'
#' @param tt_input A `tidytargets` object.
#' @param ... Named values to store. Omit to read the metadata instead.
#' @return The metadata list when reading, or the updated `tidytargets` object
#'   when writing.
#'
#' @examples
#' \dontrun{
#' pipeline <- tt_initialise() |>
#'   tt_metadata(api_url = "https://api.example.org", api_version = 2)
#'
#' pipeline |> tt_metadata()
#' tt_metadata(pipeline)$api_url
#' }
#' @details
#' The store is held under a dot-prefixed element of the object. `targets`
#' rejects target names beginning with a dot, so the store can never be shadowed
#' by a target the user adds, and metadata places no restriction on the names
#' passed to `target_output`.
#' @name tt_metadata
#' @export
tt_metadata <- function(tt_input, ...) {
  UseMethod("tt_metadata")
}

#' @rdname tt_metadata
#' @export
tt_metadata.default <- function(tt_input, ...) {
  stop_if_not_tidytargets()
}

#' @rdname tt_metadata
#' @export
tt_metadata.tidytargets <- function(tt_input, ...) {

  current <- tt_input$.metadata
  if (is.null(current)) current <- list()

  updates <- list(...)

  if (length(updates) == 0) return(current)

  if (is.null(names(updates)) || any(names(updates) == ""))
    stop(
      "tidytargets says: metadata entries must be named, ",
      "e.g. tt_metadata(x, api_url = \"https://...\"). ",
      "To read an entry use tt_metadata(x)$api_url.",
      call. = FALSE
    )

  if (anyDuplicated(names(updates)))
    stop("tidytargets says: metadata entry names must be unique.", call. = FALSE)

  # Assigning NULL drops the entry, which is the documented way to remove one
  for (entry in names(updates)) current[[entry]] <- updates[[entry]]

  tt_input$.metadata <- current

  tt_input
}
