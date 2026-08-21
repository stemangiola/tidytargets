library(testthat)
library(tidytargets)

test_that("is_target converts a string to a name symbol", {
  result <- is_target("my_target")
  expect_true(is.name(result))
  expect_equal(as.character(result), "my_target")
})

test_that("is_target returns NULL for NULL input", {
  expect_null(is_target(NULL))
})

test_that("is_target errors on non-character input", {
  expect_error(is_target(42))
})

test_that("get_positions groups indices by unique value", {
  result <- get_positions(c("a", "a", "b", "c", "a"))
  expect_type(result, "list")
  expect_equal(names(result), c("a", "b", "c"))
  expect_equal(result$a, c(1, 2, 5))
  expect_equal(result$b, 3)
})
