library(testthat)
library(tidytargets)

test_that("package_of_object is empty for NULL and plain lists of NULLs", {
  expect_equal(tidytargets:::package_of_object(NULL), character())
  expect_equal(tidytargets:::package_of_object(list(NULL, NULL)), character())
})
