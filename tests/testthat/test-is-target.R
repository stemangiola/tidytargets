library(testthat)
library(tidytargets)

test_that("package_of_object is empty for NULL and plain lists of NULLs", {
  expect_equal(tidytargets:::package_of_object(NULL), character())
  expect_equal(tidytargets:::package_of_object(list(NULL, NULL)), character())
})

test_that("tt_single has no iterate or n_units formals", {
  expect_false("iterate" %in% names(formals(tt_single)))
  expect_false("n_units" %in% names(formals(tt_single)))
})

test_that("attached_packages is names only and omits default R packages", {
  pkgs <- tidytargets:::attached_packages()
  expect_type(pkgs, "character")
  expect_true("tidytargets" %in% pkgs)
  expect_false(any(pkgs %in% c("base", "stats", "utils", "methods")))
  expect_false(any(grepl("^package:", pkgs)))
})

test_that("process_pattern maps equal sizes, drops size 1, and errors when they differ", {
  suppressMessages({
    equal_map <- tidytargets:::process_pattern(c(methods = 2L, samples = 2L))
    expect_equal(equal_map$pattern_type, "map")
    expect_equal(equal_map$pattern_names, c("methods", "samples"))
    expect_equal(equal_map$n_units, 2L)

    drop_const <- tidytargets:::process_pattern(c(const = 1L, methods = 2L, samples = 2L))
    expect_equal(drop_const$pattern_names, c("methods", "samples"))
    expect_equal(drop_const$n_units, 2L)

    crossed <- tidytargets:::process_pattern(
      c(const = 1L, methods = 2L, samples = 3L),
      "cross"
    )
    expect_equal(crossed$pattern_type, "cross")
    expect_equal(crossed$pattern_names, c("const", "methods", "samples"))
    expect_equal(crossed$n_units, 6L)

    one <- tidytargets:::process_pattern(c(methods = 2L), "cross")
    expect_equal(one$pattern_type, "map")
  })

  expect_error(
    tidytargets:::process_pattern(c(methods = 2L, samples = 3L)),
    'use pattern = "cross"',
    fixed = TRUE
  )
})

test_that("process_pattern messages mapped sizes when there are two or more inputs", {
  expect_message(
    tidytargets:::process_pattern(c(methods = 2L, samples = 2L)),
    "mapped sizes methods: 2, samples: 2; using map()",
    fixed = TRUE
  )
  expect_message(
    tidytargets:::process_pattern(c(methods = 2L, samples = 3L), "cross"),
    "crossing methods, samples (methods: 2, samples: 3)",
    fixed = TRUE
  )
  expect_silent(
    tidytargets:::process_pattern(c(methods = 2L))
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

