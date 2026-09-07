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
#' @param mem_gb_per_job Numeric vector, memory in gigabytes required per
#'   worker for each tier, ordered from smallest to largest. Tier names are
#'   generated automatically from these values (e.g. `5` becomes
#'   `"elastic_5"`).
#' @param time_min Numeric vector (or single value recycled to the number of
#'   tiers), walltime in minutes for each tier.
#' @param workers Numeric vector (or single value recycled to the number of
#'   tiers), number of workers for each tier.
#' @param crashes_max Numeric vector (or single value recycled to the number
#'   of tiers), crashes allowed on a tier before falling back to the next one
#'   up.
#' @param cpus_per_task Numeric vector (or single value recycled to the
#'   number of tiers), CPUs per task for each tier. Default: `8`.
#' @param seconds_idle Numeric seconds each worker idles before shutting
#'   down, passed to every `crew_controller_slurm()`. Default: `30`.
#' @param ... Additional arguments passed to every
#'   `crew.cluster::crew_options_slurm()` call (e.g. `partition`).
#' @return A `crew_class_controller_group` object from
#'   `crew::crew_controller_group()`.
#'
#' @examples
#' \dontrun{
#' computing_resources <- tt_controller_elastic_slurm(
#'   mem_gb_per_job = c(5, 10, 20, 40, 80, 160),
#'   time_min = c(60 * 4, 60 * 4, 60 * 4, 60 * 4, 60 * 4, 60 * 24),
#'   workers = c(64, 48, 32, 24, 16, 8),
#'   crashes_max = c(6, 1, 1, 1, 1, 2)
#' )
#' tt_initialise(computing_resources = computing_resources)
#' }
#'
#' @export
tt_controller_elastic_slurm <- function(mem_gb_per_job,
                                         time_min,
                                         workers,
                                         crashes_max,
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

  n <- length(mem_gb_per_job)
  if (n == 0L) {
    stop(
      "tidytargets says: mem_gb_per_job must have at least one value.",
      call. = FALSE
    )
  }

  tiers <- data.frame(
    name = paste0("elastic_", mem_gb_per_job),
    mem_gb_per_job = mem_gb_per_job,
    time_min = recycle_to_length(time_min, n, "time_min"),
    workers = recycle_to_length(workers, n, "workers"),
    crashes_max = recycle_to_length(crashes_max, n, "crashes_max"),
    cpus_per_task = recycle_to_length(cpus_per_task, n, "cpus_per_task"),
    stringsAsFactors = FALSE
  )

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
        memory_gigabytes_required = row$mem_gb_per_job,
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

#' Recycle a vector to a target length, erroring on incompatible lengths
#'
#' @param x Numeric vector, either length 1 (recycled) or length `n`.
#' @param n Target length (number of tiers).
#' @param arg Character name of the argument, used in the error message.
#' @return `x` recycled to length `n`.
#' @noRd
recycle_to_length <- function(x, n, arg) {
  if (length(x) == n) return(x)
  if (length(x) == 1L) return(rep(x, n))
  stop(
    "tidytargets says: `", arg, "` must have length 1 or the same length as ",
    "`mem_gb_per_job` (", n, "), not ", length(x), ".",
    call. = FALSE
  )
}
