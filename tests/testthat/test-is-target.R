library(testthat)
library(tidytargets)

test_that("package_of_object is empty for NULL and plain lists of NULLs", {
  expect_equal(tidytargets:::package_of_object(NULL), character())
  expect_equal(tidytargets:::package_of_object(list(NULL, NULL)), character())
})

test_that("attached_packages is names only and omits default R packages", {
  pkgs <- tidytargets:::attached_packages()
  expect_type(pkgs, "character")
  expect_true("tidytargets" %in% pkgs)
  expect_false(any(pkgs %in% c("base", "stats", "utils", "methods")))
  expect_false(any(grepl("^package:", pkgs)))
})

