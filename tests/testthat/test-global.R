library(testthat)
library(tidytargets)

test_that("tt_global writes the object into the script header, above the targets", {
  tmp <- tempfile("tidytargets-")
  dir.create(tmp)
  old <- setwd(tmp)
  on.exit(setwd(old), add = TRUE)

  add_one <- function(x) x + 1

  store <- file.path(tmp, "store")
  pipe <- tt_initialise(store = store, packages = "tidytargets") |>
    tt_global(add_one) |>
    tt_single(two <- add_one(1))

  script_path <- tidytargets:::write_script(pipe)
  script <- readLines(script_path)
  global_at <- grep("^add_one <- function", script)
  list_at <- grep("^\\s*target_list\\s*<-\\s*list\\(\\)\\s*$", script)
  factory_at <- grep("target_output = \"two\"", script)

  expect_length(global_at, 1L)
  expect_true(global_at < list_at)
  expect_true(list_at < factory_at)
  expect_error(parse(script_path), NA)
})

test_that("a global is recorded in $globals, not as a target", {
  tmp <- tempfile("tidytargets-")
  dir.create(tmp)
  old <- setwd(tmp)
  on.exit(setwd(old), add = TRUE)

  add_one <- function(x) x + 1

  store <- file.path(tmp, "store")
  pipe <- tt_initialise(store = store, packages = "tidytargets") |>
    tt_global(add_one)

  expect_s3_class(pipe, "tidytargets")
  expect_equal(names(pipe$globals), "add_one")
  expect_false("add_one" %in% names(pipe$targets))
  expect_length(pipe$targets, 0L)
  expect_false(file.exists(file.path(store, "add_one_data.qs")))
})

test_that("targets can call a global, including from another global", {
  tmp <- tempfile("tidytargets-")
  dir.create(tmp)
  old <- setwd(tmp)
  on.exit(setwd(old), add = TRUE)

  double_it <- function(x) x * 2
  double_then_add <- function(x) double_it(x) + 1

  store <- file.path(tmp, "store")
  pipe <- tt_initialise(store = store, packages = "tidytargets") |>
    tt_global(double_it, double_then_add) |>
    tt_single(out <- double_then_add(5))

  tt_evaluate(pipe)
  expect_equal(targets::tar_read(out, store = store), 11)
})

test_that("re-declaring a global replaces it", {
  tmp <- tempfile("tidytargets-")
  dir.create(tmp)
  old <- setwd(tmp)
  on.exit(setwd(old), add = TRUE)

  label <- "first"

  store <- file.path(tmp, "store")
  pipe <- tt_initialise(store = store, packages = "tidytargets") |>
    tt_global(label) |>
    tt_single(out <- label)

  label <- "second"
  pipe <- pipe |> tt_global(label)

  # $globals is keyed by name, so the script carries one assignment, not two
  # that shadow each other.
  expect_length(pipe$globals, 1L)
  script <- readLines(tidytargets:::write_script(pipe))
  expect_length(grep('^label <- "second"$', script), 1L)
  expect_length(grep('^label <- "first"$', script), 0L)

  tt_evaluate(pipe)
  expect_equal(targets::tar_read(out, store = store), "second")
})

test_that("tt_global snapshots the value at the moment it is declared", {
  tmp <- tempfile("tidytargets-")
  dir.create(tmp)
  old <- setwd(tmp)
  on.exit(setwd(old), add = TRUE)

  cutoff <- 1

  store <- file.path(tmp, "store")
  pipe <- tt_initialise(store = store, packages = "tidytargets") |>
    tt_global(cutoff)

  cutoff <- 999

  script <- readLines(tidytargets:::write_script(pipe))
  expect_true(any(grepl("^cutoff <- 1$", script)))
  expect_false(any(grepl("999", script)))
})

test_that("tt_global names the object from assignment or argument name", {
  tmp <- tempfile("tidytargets-")
  dir.create(tmp)
  old <- setwd(tmp)
  on.exit(setwd(old), add = TRUE)

  store <- file.path(tmp, "store")
  pipe <- tt_initialise(store = store, packages = "tidytargets") |>
    tt_global(from_assignment <- function(x) x, from_argument = 42)

  script <- readLines(tidytargets:::write_script(pipe))
  expect_true(any(grepl("^from_assignment <- function", script)))
  expect_true(any(grepl("^from_argument <- 42$", script)))
})

test_that("tt_global validates its input", {
  tmp <- tempfile("tidytargets-")
  dir.create(tmp)
  old <- setwd(tmp)
  on.exit(setwd(old), add = TRUE)

  store <- file.path(tmp, "store")
  pipe <- tt_initialise(store = store, packages = "tidytargets")

  expect_error(tt_global("not a pipeline", 1), "tidytargets object")
  expect_error(tt_global(pipe), "at least one object")
  expect_error(tt_global(pipe, 1 + 1), "please name the target")
})
