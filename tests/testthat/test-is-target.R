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

test_that("infer_iteration_strategy maps equal sizes and errors when they differ", {
  suppressMessages({
    equal_map <- tidytargets:::infer_iteration_strategy(c(methods = 2L, samples = 2L))
    expect_equal(equal_map$pattern_type, "map")
    expect_equal(equal_map$pattern_names, c("methods", "samples"))
    expect_equal(equal_map$n_units, 2L)

    auto_const <- tidytargets:::infer_iteration_strategy(
      c(const = 1L, methods = 2L, samples = 2L)
    )
    expect_equal(auto_const$pattern_type, "map")
    expect_equal(auto_const$pattern_names, c("methods", "samples"))
    expect_equal(auto_const$n_units, 2L)

    force_cross <- tidytargets:::infer_iteration_strategy(
      c(const = 1L, methods = 2L, samples = 3L),
      "cross"
    )
    expect_equal(force_cross$pattern_type, "cross")
    expect_equal(force_cross$pattern_names, c("const", "methods", "samples"))
    expect_equal(force_cross$n_units, 6L)

    one <- tidytargets:::infer_iteration_strategy(c(methods = 2L), "cross")
    expect_equal(one$pattern_type, "map")

    all_one <- tidytargets:::infer_iteration_strategy(c(a = 1L, b = 1L))
    expect_equal(all_one$pattern_type, "map")
    expect_equal(all_one$pattern_names, c("a", "b"))
    expect_equal(all_one$n_units, 1L)

    missing <- tidytargets:::infer_iteration_strategy(c(a = 2L, e = NA_integer_))
    expect_equal(missing$pattern_type, "map")

    empty <- tidytargets:::infer_iteration_strategy(setNames(integer(), character()))
    expect_equal(empty$pattern_type, "map")

    two_const <- tidytargets:::infer_iteration_strategy(
      c(const = 1L, extra = 1L, methods = 4L, samples = 4L)
    )
    expect_equal(two_const$pattern_type, "map")
    expect_equal(two_const$pattern_names, c("methods", "samples"))
  })

  expect_error(
    tidytargets:::infer_iteration_strategy(c(methods = 2L, samples = 3L)),
    'use pattern = "cross"',
    fixed = TRUE
  )
  expect_error(
    tidytargets:::infer_iteration_strategy(
      c(const = 1L, extra = 1L, methods = 4L, other = 5L)
    ),
    'use pattern = "cross"',
    fixed = TRUE
  )
})

test_that("infer_iteration_strategy messages mapped sizes when there are two or more inputs", {
  expect_message(
    tidytargets:::infer_iteration_strategy(c(methods = 2L, samples = 2L)),
    "mapped sizes methods: 2, samples: 2; using map()",
    fixed = TRUE
  )
  expect_silent(
    tidytargets:::infer_iteration_strategy(c(methods = 2L))
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

