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

  script <- readLines(paste0(store, ".R"))
  global_at <- grep("^add_one <- function", script)
  list_at <- grep("^\\s*target_list\\s*<-\\s*list\\(\\)\\s*$", script)
  factory_at <- grep("target_output = \"two\"", script)

  expect_length(global_at, 1L)
  expect_true(global_at < list_at)
  expect_true(list_at < factory_at)
  expect_error(parse(paste0(store, ".R")), NA)
})

test_that("a global is not a target", {
  tmp <- tempfile("tidytargets-")
  dir.create(tmp)
  old <- setwd(tmp)
  on.exit(setwd(old), add = TRUE)

  add_one <- function(x) x + 1

  store <- file.path(tmp, "store")
  pipe <- tt_initialise(store = store, packages = "tidytargets") |>
    tt_global(add_one)

  expect_s3_class(pipe, "tidytargets")
  expect_equal(names(pipe), c("initialisation", "metadata", "targets"))
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

test_that("the last declaration of a global is the one targets see", {
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

  script <- readLines(paste0(store, ".R"))
  first_at <- grep('^label <- "first"$', script)
  second_at <- grep('^label <- "second"$', script)
  expect_length(first_at, 1L)
  expect_length(second_at, 1L)
  expect_true(first_at < second_at)

  tt_evaluate(pipe)
  expect_equal(targets::tar_read(out, store = store), "second")
})

test_that("tt_global names the object from assignment or argument name", {
  tmp <- tempfile("tidytargets-")
  dir.create(tmp)
  old <- setwd(tmp)
  on.exit(setwd(old), add = TRUE)

  store <- file.path(tmp, "store")
  pipe <- tt_initialise(store = store, packages = "tidytargets") |>
    tt_global(from_assignment <- function(x) x, from_argument = 42)

  script <- readLines(paste0(store, ".R"))
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
