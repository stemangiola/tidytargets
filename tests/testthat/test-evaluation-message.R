test_that("a pipeline left unevaluated is the one that says it is ready", {
  on.exit(pipeline_pending_flush(), add = TRUE)

  expect_message(pipeline_ready_message(), "ready to be evaluated")

  # Nothing built, nothing to announce.
  expect_false(pipeline_pending_flush())

  # Built and left alone: said once, then forgotten, so the next expression
  # does not repeat it.
  pipeline_pending_add("store_a")
  expect_true(pipeline_pending_flush())
  expect_false(pipeline_pending_flush())

  # Printing runs the pipeline before the notice is due, which is what keeps
  # the message from contradicting a result that has already been shown.
  pipeline_pending_add("store_a")
  mark_pipeline_evaluated("store_a")
  expect_false(pipeline_pending_flush())

  # Stores are tracked one by one, so running one pipeline does not silence
  # another built in the same expression.
  pipeline_pending_add("store_a")
  pipeline_pending_add("store_b")
  mark_pipeline_evaluated("store_a")
  expect_true(pipeline_pending_flush())

  # A store that was never built, and a pipeline carrying no store at all.
  expect_silent(mark_pipeline_evaluated("store_absent"))
  expect_silent(pipeline_pending_add(NULL))
  expect_false(pipeline_pending_flush())
})

test_that("tt_evaluate generic forgets a store before the method runs", {
  on.exit(pipeline_pending_flush(), add = TRUE)

  pipeline_pending_add("store_a")
  fake <- list(initialisation = list(store = "store_a"))
  expect_error(tt_evaluate(fake), "tidytargets object")
  expect_false(pipeline_pending_flush())
})

test_that("non-interactive sessions never queue a notice", {
  skip_if(interactive())
  on.exit(pipeline_pending_flush(), add = TRUE)

  schedule_pipeline_ready_notice("store_a")
  expect_false(pipeline_pending_flush())
})

test_that("task callback names come from base", {
  expect_type(getTaskCallbackNames(), "character")
})
