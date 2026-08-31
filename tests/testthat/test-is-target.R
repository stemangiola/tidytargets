library(testthat)
library(tidytargets)

test_that("new_tidytargets and append_step keep class and separate slots", {
  pipe <- tidytargets:::new_tidytargets(list(store = "s"))
  expect_s3_class(pipe, "tidytargets")
  expect_equal(names(pipe), c("initialisation", "metadata", "targets"))
  expect_equal(names(pipe$targets), character())
  expect_equal(pipe$metadata, list())

  pipe <- tidytargets:::append_step(
    pipe,
    "fit",
    list(command = quote(1), iterate = "none")
  )
  expect_s3_class(pipe, "tidytargets")
  expect_equal(names(pipe), c("initialisation", "metadata", "targets"))
  expect_equal(names(pipe$targets), "fit")
  expect_equal(pipe$targets$fit$iterate, "none")
  expect_equal(pipe$initialisation$store, "s")
})

test_that("package_of_object is empty for NULL and plain lists of NULLs", {
  expect_equal(tidytargets:::package_of_object(NULL), character())
  expect_equal(tidytargets:::package_of_object(list(NULL, NULL)), character())
})

test_that("tt_single and tt_split have no iterate or n_units formals", {
  expect_false("iterate" %in% names(formals(tt_single)))
  expect_false("n_units" %in% names(formals(tt_single)))
  expect_false("n_units" %in% names(formals(tt_split)))
  expect_false("n_units" %in% names(formals(tt_data_list)))
})

test_that("attached_packages is names only and omits default R packages", {
  pkgs <- tidytargets:::attached_packages()
  expect_type(pkgs, "character")
  expect_true("tidytargets" %in% pkgs)
  expect_false(any(pkgs %in% c("base", "stats", "utils", "methods")))
  expect_false(any(grepl("^package:", pkgs)))
})

test_that("resolve_pattern maps all names and crosses when asked", {
  suppressMessages({
    equal_map <- tidytargets:::resolve_pattern(c("methods", "samples"))
    expect_equal(equal_map$pattern_type, "map")
    expect_equal(equal_map$pattern_names, c("methods", "samples"))

    crossed <- tidytargets:::resolve_pattern(
      c("const", "methods", "samples"),
      "cross"
    )
    expect_equal(crossed$pattern_type, "cross")
    expect_equal(crossed$pattern_names, c("const", "methods", "samples"))

    one <- tidytargets:::resolve_pattern("methods", "cross")
    expect_equal(one$pattern_type, "map")
  })
})

test_that("resolve_pattern messages when there are two or more inputs", {
  expect_message(
    tidytargets:::resolve_pattern(c("methods", "samples")),
    "using map()",
    fixed = TRUE
  )
  expect_message(
    tidytargets:::resolve_pattern(c("methods", "samples"), "cross"),
    "crossing methods, samples",
    fixed = TRUE
  )
  expect_silent(
    tidytargets:::resolve_pattern("methods")
  )
})

test_that("tt_factory builds map() and cross() patterns", {
  mapped <- tt_factory(
    command = quote(a + b),
    target_output = "out",
    other_arguments_to_map = c("a", "b"),
    pattern_type = "map"
  )
  crossed <- tt_factory(
    command = quote(a + b),
    target_output = "out",
    other_arguments_to_map = c("a", "b"),
    pattern_type = "cross"
  )
  expect_equal(mapped$settings$pattern, expression(map(a, b)))
  expect_equal(crossed$settings$pattern, expression(cross(a, b)))
})

