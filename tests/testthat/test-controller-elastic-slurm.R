library(testthat)
library(tidytargets)

test_that("tt_controller_elastic_slurm errors when crew/crew.cluster are unavailable", {
  skip_if(
    requireNamespace("crew", quietly = TRUE) &&
      requireNamespace("crew.cluster", quietly = TRUE),
    "crew and crew.cluster are installed; cannot test the missing-package error"
  )
  expect_error(
    tt_controller_elastic_slurm(workers = 2, mem_gb_per_job = 5),
    "crew.*required"
  )
})

test_that("tt_controller_elastic_slurm requires workers", {
  skip_if_not_installed("crew")
  skip_if_not_installed("crew.cluster")

  expect_error(
    tt_controller_elastic_slurm(mem_gb_per_job = c(5, 10)),
    "workers"
  )
})

test_that("tt_controller_elastic_slurm validates tier lengths", {
  skip_if_not_installed("crew")
  skip_if_not_installed("crew.cluster")

  expect_error(
    tt_controller_elastic_slurm(workers = 2, mem_gb_per_job = numeric(0)),
    "at least one value"
  )

  expect_error(
    tt_controller_elastic_slurm(
      workers = 1, mem_gb_per_job = c(5, 10), time_hours = c(1, 2, 3)
    ),
    "must have length 1 or the same length"
  )
})

test_that("tt_controller_elastic_slurm chains backups from small to large and auto-names tiers", {
  skip_if_not_installed("crew")
  skip_if_not_installed("crew.cluster")

  group <- tt_controller_elastic_slurm(
    mem_gb_per_job = c(5, 10, 20),
    time_hours = c(4, 4, 4),
    workers = c(64, 48, 32),
    crashes_max = c(6, 1, 1)
  )
  controllers <- group$controllers
  expect_length(controllers, 3)

  names_in_group <- unname(
    vapply(controllers, function(x) x$launcher$name, character(1))
  )
  expect_equal(names_in_group, c("elastic_5", "elastic_10", "elastic_20"))

  # Smallest tier falls back to the next tier up; largest has no backup.
  expect_equal(controllers[[1]]$backup$launcher$name, "elastic_10")
  expect_equal(controllers[[2]]$backup$launcher$name, "elastic_20")
  expect_null(controllers[[3]]$backup)

  expect_equal(
    controllers[[1]]$launcher$options_cluster$memory_gigabytes_required, 5
  )
  expect_equal(controllers[[1]]$launcher$options_cluster$cpus_per_task, 1)
  # time_hours is converted to the minutes crew.cluster expects.
  expect_equal(controllers[[1]]$launcher$options_cluster$time_minutes, 4 * 60)
})

test_that("tt_controller_elastic_slurm honors per-tier cpus_per_task and dots", {
  skip_if_not_installed("crew")
  skip_if_not_installed("crew.cluster")

  group <- tt_controller_elastic_slurm(
    mem_gb_per_job = c(5, 50),
    time_hours = 1,
    workers = c(4, 2),
    crashes_max = 1,
    cpus_per_task = c(4, 16),
    partition = "standard"
  )
  controllers <- group$controllers

  expect_equal(controllers[[1]]$launcher$options_cluster$cpus_per_task, 4)
  expect_equal(controllers[[2]]$launcher$options_cluster$cpus_per_task, 16)
  expect_equal(controllers[[1]]$launcher$options_cluster$partition, "standard")
  expect_equal(controllers[[1]]$launcher$options_cluster$time_minutes, 60)
  expect_equal(controllers[[1]]$backup$launcher$name, "elastic_50")
  expect_null(controllers[[2]]$backup)
})

test_that("a controller group is rebuilt in the script, so a target can pick a tier", {
  skip_if_not_installed("crew")

  tmp <- tempfile("tidytargets-")
  dir.create(tmp)
  old <- setwd(tmp)
  on.exit(setwd(old), add = TRUE)

  tiers <- crew::crew_controller_group(
    crew::crew_controller_local(name = "small", workers = 1),
    crew::crew_controller_local(name = "big", workers = 1)
  )

  pipe <- tt_initialise(
    store = file.path(tmp, "store"),
    computing_resources = tiers,
    packages = "tidytargets"
  ) |>
    tt_single(
      pinned <- 1,
      resources = quote(tar_resources(crew = tar_resources_crew(controller = "big")))
    )

  # Only the controllers can be serialised: a restored group holds dead
  # condition variables, so the script assembles the group itself.
  snapshot <- qs2::qs_read(
    file.path(pipe$initialisation$store, "temp_computing_resources.qs")
  )
  expect_equal(names(snapshot), c("small", "big"))

  script <- tidytargets:::write_script(pipe)
  expect_match(
    paste(readLines(script), collapse = " "),
    "do.call(crew_controller_group",
    fixed = TRUE
  )

  # Run in-process so this session's factory forwards resources; tar_make()
  # via callr would load the installed one.
  targets::tar_make(
    callr_function = NULL,
    script = script,
    store = pipe$initialisation$store,
    reporter = "silent"
  )
  expect_equal(
    targets::tar_read(pinned, store = pipe$initialisation$store),
    1
  )
})

test_that("tt_controller_elastic_slurm defaults every argument but workers and mem_gb_per_job", {
  skip_if_not_installed("crew")
  skip_if_not_installed("crew.cluster")

  # workers and mem_gb_per_job are required; everything else falls back to a
  # single default value, recycled across all tiers.
  group <- tt_controller_elastic_slurm(
    workers = 8, mem_gb_per_job = c(5, 10, 20, 50, 100)
  )
  controllers <- group$controllers
  expect_length(controllers, 5)

  names_in_group <- unname(
    vapply(controllers, function(x) x$launcher$name, character(1))
  )
  expect_equal(
    names_in_group,
    c("elastic_5", "elastic_10", "elastic_20", "elastic_50", "elastic_100")
  )

  for (controller in controllers) {
    expect_equal(controller$launcher$workers, 8)
    expect_equal(controller$crashes_max, 2)
    expect_equal(controller$launcher$options_cluster$cpus_per_task, 1)
    expect_equal(controller$launcher$options_cluster$time_minutes, 24 * 60)
  }
  expect_null(controllers[[5]]$backup)
})
