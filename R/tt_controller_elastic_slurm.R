#' Build an elastic SLURM crew controller group
#'
#' @description
#' Wraps a common `{crew.cluster}` HPC pattern: several
#' `crew.cluster::crew_controller_slurm()` resource tiers, sized from small to
#' large, each one falling back to the next tier up (via its `backup`
#' argument) once its workers exhaust `crashes_max`. Returns a
#' `crew::crew_controller_group()`, ready to pass to
#' `tt_initialise(computing_resources = )`. tidytargets does not depend on
#' `{crew}`/`{crew.cluster}`; install them yourself to use this wrapper.
#'
#' @param tiers A data frame (or a list coercible to one with
#'   `dplyr::bind_rows()`) with one row per resource tier, ordered from
#'   smallest to largest. Required columns: `name` (character), `mem_gb`
#'   (memory in gigabytes required per worker), `time_min` (walltime in
#'   minutes), `workers` (number of workers for that tier), and
#'   `crashes_max` (crashes allowed on a tier before falling back to the
#'   next one up). An optional `cpus_per_task` column overrides
#'   `cpus_per_task` per tier. The smallest tier (first row) is tried
#'   first; each tier's `backup` is the next largest tier, and the largest
#'   tier (last row) has no backup.
#' @param cpus_per_task Default CPUs per task for tiers that do not supply
#'   their own `cpus_per_task` column. Default: `8`.
#' @param seconds_idle Numeric seconds each worker idles before shutting
#'   down, passed to every `crew_controller_slurm()`. Default: `30`.
#' @param ... Additional arguments passed to every
#'   `crew.cluster::crew_options_slurm()` call (e.g. `partition`).
#' @return A `crew_class_controller_group` object from
#'   `crew::crew_controller_group()`.
#'
#' @examples
#' \dontrun{
#' tiers <- data.frame(
#'   name = c(
#'     "elastic_5", "elastic_10", "elastic_20",
#'     "elastic_40", "elastic_80", "elastic_160"
#'   ),
#'   mem_gb = c(5, 10, 20, 40, 80, 160),
#'   time_min = c(60 * 4, 60 * 4, 60 * 4, 60 * 4, 60 * 4, 60 * 24),
#'   workers = c(64, 48, 32, 24, 16, 8),
#'   crashes_max = c(6, 1, 1, 1, 1, 2)
#' )
#' computing_resources <- tt_controller_elastic_slurm(tiers)
#' tt_initialise(computing_resources = computing_resources)
#' }
#'
#' @export
tt_controller_elastic_slurm <- function(tiers,
                                         cpus_per_task = 8,
                                         seconds_idle = 30,
                                         ...) {
  if (!requireNamespace("crew", quietly = TRUE) ||
      !requireNamespace("crew.cluster", quietly = TRUE)) {
    stop(
      "tidytargets says: tt_controller_elastic_slurm() needs the {crew} and ",
      "{crew.cluster} packages. Install them with ",
      'install.packages(c("crew", "crew.cluster")).',
      call. = FALSE
    )
  }

  tiers <- dplyr::bind_rows(tiers)

  required <- c("name", "mem_gb", "time_min", "workers", "crashes_max")
  missing_cols <- setdiff(required, names(tiers))
  if (length(missing_cols) > 0) {
    stop(
      "tidytargets says: tiers is missing required column(s): ",
      paste(missing_cols, collapse = ", "), ".",
      call. = FALSE
    )
  }

  n <- nrow(tiers)
  if (n == 0L) {
    stop("tidytargets says: tiers must have at least one row.", call. = FALSE)
  }

  # `dplyr::bind_rows()` fills a partially-supplied `cpus_per_task` column
  # with `NA` for rows that omitted it, rather than leaving the column out.
  if (!"cpus_per_task" %in% names(tiers)) {
    tiers$cpus_per_task <- cpus_per_task
  } else {
    tiers$cpus_per_task[is.na(tiers$cpus_per_task)] <- cpus_per_task
  }

  controllers <- vector("list", n)
  backup <- NULL

  # Build from the largest tier (last row) down to the smallest (first row),
  # so each smaller tier's `backup` is the already-built next tier up.
  for (i in rev(seq_len(n))) {
    row <- tiers[i, ]
    controllers[[i]] <- crew.cluster::crew_controller_slurm(
      name = row$name,
      workers = row$workers,
      crashes_max = row$crashes_max,
      seconds_idle = seconds_idle,
      options_cluster = crew.cluster::crew_options_slurm(
        memory_gigabytes_required = row$mem_gb,
        cpus_per_task = row$cpus_per_task,
        time_minutes = row$time_min,
        ...
      ),
      backup = backup
    )
    backup <- controllers[[i]]
  }

  do.call(crew::crew_controller_group, controllers)
}
