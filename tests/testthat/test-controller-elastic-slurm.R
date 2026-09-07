library(testthat)
library(tidytargets)

test_that("tt_controller_elastic_slurm errors when crew/crew.cluster are unavailable", {
  skip_if(
    requireNamespace("crew", quietly = TRUE) &&
      requireNamespace("crew.cluster", quietly = TRUE),
    "crew and crew.cluster are installed; cannot test the missing-package error"
  )
  expect_error(
    tt_controller_elastic_slurm(
      mem_gb_per_job = 5, time_min = 60, workers = 2, crashes_max = 1
    ),
    "needs the \\{crew\\} and \\{crew.cluster\\} packages"
  )
})

test_that("tt_controller_elastic_slurm validates tier lengths", {
  skip_if_not_installed("crew")
  skip_if_not_installed("crew.cluster")

  expect_error(
    tt_controller_elastic_slurm(
      mem_gb_per_job = numeric(0), time_min = 60, workers = 2, crashes_max = 1
    ),
    "at least one value"
  )

  expect_error(
    tt_controller_elastic_slurm(
      mem_gb_per_job = c(5, 10), time_min = c(1, 2, 3),
      workers = 1, crashes_max = 1
    ),
    "must have length 1 or the same length"
  )
})

test_that("tt_controller_elastic_slurm chains backups from small to large and auto-names tiers", {
  skip_if_not_installed("crew")
  skip_if_not_installed("crew.cluster")

  group <- tt_controller_elastic_slurm(
    mem_gb_per_job = c(5, 10, 20),
    time_min = c(60 * 4, 60 * 4, 60 * 4),
    workers = c(64, 48, 32),
    crashes_max = c(6, 1, 1)
  )
  controllers <- group$controllers
  expect_length(controllers, 3)

  names_in_group <- vapply(controllers, function(x) x$name, character(1))
  expect_equal(names_in_group, c("elastic_5", "elastic_10", "elastic_20"))

  # Smallest tier falls back to the next tier up; largest has no backup.
  expect_equal(controllers[[1]]$backup$name, "elastic_10")
  expect_equal(controllers[[2]]$backup$name, "elastic_20")
  expect_null(controllers[[3]]$backup)

  expect_equal(controllers[[1]]$options_cluster$memory_gigabytes_required, 5)
  expect_equal(controllers[[1]]$options_cluster$cpus_per_task, 8)
})

test_that("tt_controller_elastic_slurm honors per-tier cpus_per_task and dots", {
  skip_if_not_installed("crew")
  skip_if_not_installed("crew.cluster")

  group <- tt_controller_elastic_slurm(
    mem_gb_per_job = c(5, 50),
    time_min = 60,
    workers = c(4, 2),
    crashes_max = 1,
    cpus_per_task = c(4, 16),
    partition = "standard"
  )
  controllers <- group$controllers

  expect_equal(controllers[[1]]$options_cluster$cpus_per_task, 4)
  expect_equal(controllers[[2]]$options_cluster$cpus_per_task, 16)
  expect_equal(controllers[[1]]$options_cluster$partition, "standard")
  expect_equal(controllers[[1]]$backup$name, "elastic_50")
  expect_null(controllers[[2]]$backup)
})
