library(testthat)
library(tidytargets)

test_that("tt_initialise returns a tidytargets object with input targets", {
  tmp <- tempfile("tidytargets-")
  dir.create(tmp)
  old <- setwd(tmp)
  on.exit(setwd(old), add = TRUE)

  files <- c(
    sample_a = file.path(tmp, "a.rds"),
    sample_b = file.path(tmp, "b.rds")
  )
  saveRDS(1:3, files[[1]])
  saveRDS(4:6, files[[2]])

  store <- file.path(tmp, "store")
  hpc <- files |>
    tt_initialise(store = store)

  expect_s3_class(hpc, "tidytargets")
  expect_equal(hpc$initialisation$store, store)
  expect_true(file.exists(paste0(store, ".R")))
  expect_true("input_list" %in% names(hpc))
  expect_true("sample_names" %in% names(hpc))
  expect_equal(hpc$input_list$iterate, "map")
  expect_equal(hpc$sample_names$iterate, "map")
  expect_null(hpc$initialisation$computing_resources)

  script <- readLines(paste0(store, ".R"))
  expect_false(any(grepl('library\\("crew', script)))
  expect_false(any(grepl("crew_controller_group", script)))
  expect_true(any(grepl("controller = readRDS", script)))
})

test_that("tt_iterate and tt_single chain onto a tidytargets object", {

  tmp <- tempfile("tidytargets-")
  dir.create(tmp)
  old <- setwd(tmp)
  on.exit(setwd(old), add = TRUE)

  files <- c(sample_a = file.path(tmp, "a.rds"))
  saveRDS(1:3, files[[1]])

  store <- file.path(tmp, "store")
  hpc <- files |>
    tt_initialise(store = store) |>
    tt_iterate(
      target_output = "data",
      user_function = readRDS |> quote(),
      file = "input_list" |> is_target()
    ) |>
    tt_single(
      target_output = "n_inputs",
      user_function = length |> quote(),
      x = "sample_names" |> is_target()
    )

  expect_s3_class(hpc, "tidytargets")
  expect_true("data" %in% names(hpc))
  expect_equal(hpc$data$iterate, "map")
  expect_true("n_inputs" %in% names(hpc))
  expect_equal(hpc$n_inputs$iterate, "none")

  script <- readLines(paste0(store, ".R"))
  expect_true(any(grepl("target_output = \"data\"", script)))
  expect_true(any(grepl("target_output = \"n_inputs\"", script)))
})

test_that("grammar steps error on non-tidytargets input", {
  expect_error(tt_iterate("not a pipeline"), "tidytargets object")
  expect_error(tt_single("not a pipeline"), "tidytargets object")
  expect_error(tt_merge("not a pipeline"), "tidytargets object")
  expect_error(tt_report("not a pipeline"), "tidytargets object")
  expect_error(tt_evaluate("not a pipeline"), "tidytargets object")
})
