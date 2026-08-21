library(testthat)
library(tidytargets)

test_that("collapse_arguments wraps names in purrr::list_flatten", {
  nested <- list(list("a1", "a2"), list("b1", "b2"))
  wrapped <- tidytargets:::collapse_arguments(list(x = as.name("chunks"), n = 1L))

  expect_equal(wrapped$n, 1L)

  inner <- wrapped$x
  while (is.call(inner) && identical(inner[[1]], as.name("quote"))) {
    inner <- inner[[2]]
  }
  expect_equal(inner, quote(purrr::list_flatten(chunks)))
  expect_equal(
    unname(eval(inner, list(chunks = nested))),
    list("a1", "a2", "b1", "b2")
  )
})

test_that("tt_merge collapse writes list_flatten into the targets script", {
  tmp <- tempfile("tidytargets-")
  dir.create(tmp)
  old <- setwd(tmp)
  on.exit(setwd(old), add = TRUE)

  files <- c(sample_a = file.path(tmp, "a.rds"))
  saveRDS(list("a1", "a2"), files[[1]])

  store <- file.path(tmp, "store")
  files |>
    tt_initialise(store = store) |>
    tt_iterate(
      target_output = "chunks",
      user_function = readRDS |> quote(),
      file = "input_list" |> is_target()
    ) |>
    tt_merge(
      target_output = "all_chunks",
      user_function = identity |> quote(),
      collapse = TRUE,
      x = "chunks" |> is_target()
    )

  script <- readLines(paste0(store, ".R"))
  expect_true(any(grepl("purrr::list_flatten", script, fixed = TRUE)))
  expect_false(any(grepl("collapse = TRUE", script)))
})

test_that("tt_merge without collapse does not flatten", {
  tmp <- tempfile("tidytargets-")
  dir.create(tmp)
  old <- setwd(tmp)
  on.exit(setwd(old), add = TRUE)

  files <- c(sample_a = file.path(tmp, "a.rds"))
  saveRDS(list("a1", "a2"), files[[1]])

  store <- file.path(tmp, "store")
  files |>
    tt_initialise(store = store) |>
    tt_iterate(
      target_output = "chunks",
      user_function = readRDS |> quote(),
      file = "input_list" |> is_target()
    ) |>
    tt_merge(
      target_output = "all_chunks",
      user_function = identity |> quote(),
      x = "chunks" |> is_target()
    )

  script <- readLines(paste0(store, ".R"))
  expect_false(any(grepl("purrr::list_flatten", script, fixed = TRUE)))
})

test_that("tt_merge collapse flattens a list of lists when evaluated", {
  tmp <- tempfile("tidytargets-")
  dir.create(tmp)
  old <- setwd(tmp)
  on.exit(setwd(old), add = TRUE)

  files <- c(
    sample_a = file.path(tmp, "a.rds"),
    sample_b = file.path(tmp, "b.rds")
  )
  saveRDS(list("a1", "a2"), files[[1]])
  saveRDS(list("b1", "b2"), files[[2]])

  store <- file.path(tmp, "store")
  files |>
    tt_initialise(store = store, verbosity = "silent") |>
    tt_iterate(
      target_output = "chunks",
      user_function = readRDS |> quote(),
      file = "input_list" |> is_target()
    ) |>
    tt_merge(
      target_output = "all_chunks",
      user_function = identity |> quote(),
      collapse = TRUE,
      x = "chunks" |> is_target()
    ) |>
    tt_evaluate()

  result <- targets::tar_read(all_chunks, store = store)
  expect_equal(
    sort(unlist(result, use.names = FALSE)),
    c("a1", "a2", "b1", "b2")
  )
  expect_equal(length(result), 4L)
})

test_that("two tt_merge calls in a row do not flatten", {
  tmp <- tempfile("tidytargets-")
  dir.create(tmp)
  old <- setwd(tmp)
  on.exit(setwd(old), add = TRUE)

  files <- c(
    sample_a = file.path(tmp, "a.rds"),
    sample_b = file.path(tmp, "b.rds")
  )
  saveRDS(list("a1", "a2"), files[[1]])
  saveRDS(list("b1", "b2"), files[[2]])

  store <- file.path(tmp, "store")
  files |>
    tt_initialise(store = store, verbosity = "silent") |>
    tt_iterate(
      target_output = "chunks",
      user_function = readRDS |> quote(),
      file = "input_list" |> is_target()
    ) |>
    tt_merge(
      target_output = "merged_once",
      user_function = identity |> quote(),
      x = "chunks" |> is_target()
    ) |>
    tt_merge(
      target_output = "merged_twice",
      user_function = identity |> quote(),
      x = "merged_once" |> is_target()
    ) |>
    tt_evaluate()

  once <- targets::tar_read(merged_once, store = store)
  twice <- targets::tar_read(merged_twice, store = store)
  expect_equal(once, twice)
  expect_equal(length(once), 2L)
  expect_true(all(vapply(once, is.list, logical(1))))
})

test_that("tt_merge collapse errors when the pipeline is tiered", {
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
  expect_error(
    files |>
      tt_initialise(store = store, tier = c(1, 2)) |>
      tt_merge(
        target_output = "all_chunks",
        user_function = identity |> quote(),
        collapse = TRUE,
        x = "input_list" |> is_target()
      ),
    "collapse = TRUE cannot be used with a tiered pipeline"
  )
})
