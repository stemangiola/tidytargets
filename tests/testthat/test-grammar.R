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
  expect_equal(
    hpc$initialisation$store,
    normalizePath(store, winslash = "/", mustWork = TRUE)
  )
  expect_true(file.exists(paste0(hpc$initialisation$store, ".R")))
  expect_true("input_list" %in% names(hpc))
  expect_true("sample_names" %in% names(hpc))
  expect_equal(hpc$input_list$iterate, "map")
  expect_equal(hpc$sample_names$iterate, "map")
  expect_null(hpc$initialisation$computing_resources)

  script <- readLines(paste0(store, ".R"))
  expect_false(any(grepl('library\\("crew', script)))
  expect_false(any(grepl("crew_controller_group", script)))
  expect_true(any(grepl("controller = qs_read", script)))
  expect_true(any(grepl('format = "qs"', script)))
})

test_that("tt_initialise defaults store to ./tidytargets-<hash> and messages", {
  tmp <- tempfile("tidytargets-")
  dir.create(tmp)
  old <- setwd(tmp)
  on.exit(setwd(old), add = TRUE)

  inputs <- list(sample_a = 1:3, sample_b = 4:6)
  expect_message(
    hpc <- inputs |> tt_initialise(),
    "tidytargets says: the store is \\./tidytargets-"
  )

  expect_match(basename(hpc$initialisation$store), "^tidytargets-")
  expect_true(dir.exists(hpc$initialisation$store))
  expect_true(file.exists(paste0(hpc$initialisation$store, ".R")))

  store <- file.path(tmp, "explicit-store")
  expect_no_message(inputs |> tt_initialise(store = store))
})

test_that("tt_initialise works with no mapped input", {
  tmp <- tempfile("tidytargets-")
  dir.create(tmp)
  old <- setwd(tmp)
  on.exit(setwd(old), add = TRUE)

  store <- file.path(tmp, "store")
  pipe <- tt_initialise(store = store)

  expect_s3_class(pipe, "tidytargets")
  expect_false("input_list" %in% names(pipe))
  expect_false("sample_names" %in% names(pipe))
  expect_false(file.exists(file.path(store, "input_file.qs")))
  expect_false(file.exists(file.path(store, "sample_names.qs")))
  expect_true(file.exists(paste0(store, ".R")))

  extra <- 10:12
  pipe <- pipe |> tt_data(extra)
  tt_evaluate(pipe)
  expect_equal(
    targets::tar_read(extra, store = pipe$initialisation$store),
    extra
  )
})

test_that("tt_initialise accepts a named list of objects", {
  tmp <- tempfile("tidytargets-")
  dir.create(tmp)
  old <- setwd(tmp)
  on.exit(setwd(old), add = TRUE)

  inputs <- list(sample_a = 1:3, sample_b = 4:6)
  store <- file.path(tmp, "store")
  hpc <- inputs |>
    tt_initialise(store = store)

  expect_s3_class(hpc, "tidytargets")
  expect_equal(
    hpc$initialisation$store,
    normalizePath(store, winslash = "/", mustWork = TRUE)
  )
  expect_true(file.exists(paste0(hpc$initialisation$store, ".R")))
  expect_true("input_list" %in% names(hpc))
  expect_true("sample_names" %in% names(hpc))
  expect_equal(hpc$input_list$iterate, "map")
  expect_equal(
    qs2::qs_read(file.path(hpc$initialisation$store, "sample_names.qs")),
    c("sample_a", "sample_b")
  )
  expect_equal(qs2::qs_read(file.path(hpc$initialisation$store, "input_file.qs")), inputs)
})

test_that("tt_initialise names an unnamed list with integer indices", {
  tmp <- tempfile("tidytargets-")
  dir.create(tmp)
  old <- setwd(tmp)
  on.exit(setwd(old), add = TRUE)

  hpc <- list(1:3, 4:6) |>
    tt_initialise(store = file.path(tmp, "store"))

  expect_s3_class(hpc, "tidytargets")
  expect_equal(
    qs2::qs_read(file.path(hpc$initialisation$store, "sample_names.qs")),
    c("1", "2")
  )
})

test_that("tt_initialise target_output names the mapped input target", {
  tmp <- tempfile("tidytargets-")
  dir.create(tmp)
  old <- setwd(tmp)
  on.exit(setwd(old), add = TRUE)

  inputs <- list(sample_a = 1:3, sample_b = 4:6)
  hpc <- inputs |>
    tt_initialise(store = file.path(tmp, "store"), target_output = "samples")

  expect_true("samples" %in% names(hpc))
  expect_true("samples_file" %in% names(hpc))
  expect_false("input_list" %in% names(hpc))
  expect_equal(hpc$samples$iterate, "map")
  expect_equal(hpc$initialisation$target_output, "samples")
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
      command = readRDS(input_list),
      target_output = "data"
    ) |>
    tt_single(
      command = length(sample_names),
      target_output = "n_inputs"
    )

  expect_s3_class(hpc, "tidytargets")
  expect_true("data" %in% names(hpc))
  expect_equal(hpc$data$iterate, "map")
  expect_true("n_inputs" %in% names(hpc))
  expect_equal(hpc$n_inputs$iterate, "none")

  script <- readLines(paste0(store, ".R"))
  expect_true(any(grepl("target_output = \"data\"", script)))
  expect_true(any(grepl("target_output = \"n_inputs\"", script)))
  expect_true(any(grepl("quote\\(readRDS\\(input_list\\)\\)", script)))
  expect_true(any(grepl("other_arguments_to_map = \"input_list\"", script)))
  expect_true(any(grepl("^target_list <- target_list \\|> target_append", script)))
})

test_that("grammar steps error on non-tidytargets input", {
  expect_error(tt_iterate("not a pipeline"), "tidytargets object")
  expect_error(tt_single("not a pipeline"), "tidytargets object")
  expect_error(tt_merge("not a pipeline"), "tidytargets object")
  expect_error(tt_report("not a pipeline"), "tidytargets object")
  expect_error(tt_evaluate("not a pipeline"), "tidytargets object")
  expect_error(tt_metadata("not a pipeline"), "tidytargets object")
  expect_error(tt_explore("not a pipeline", "data"), "tidytargets object")
  expect_error(tt_data("not a pipeline", 1, target_output = "x"), "tidytargets object")
  expect_error(tt_data_list("not a pipeline", list(1), target_output = "x"), "tidytargets object")
})

test_that("grammar steps require a target_output name", {
  tmp <- tempfile("tidytargets-")
  dir.create(tmp)
  old <- setwd(tmp)
  on.exit(setwd(old), add = TRUE)

  pipe <- tt_initialise(store = file.path(tmp, "store"))
  expect_error(tt_single(pipe, command = 1), "target_output")
  expect_error(tt_iterate(pipe, command = 1), "target_output")
  expect_error(tt_merge(pipe, command = 1), "target_output")
})

test_that("<- names the target and peels the command", {
  tmp <- tempfile("tidytargets-")
  dir.create(tmp)
  old <- setwd(tmp)
  on.exit(setwd(old), add = TRUE)

  files <- c(sample_a = file.path(tmp, "a.rds"))
  saveRDS(1:3, files[[1]])

  store <- file.path(tmp, "store")
  hpc <- files |>
    tt_initialise(store = store) |>
    tt_iterate(data <- readRDS(input_list)) |>
    tt_single(n_inputs <- length(sample_names)) |>
    tt_merge(n_total <- sum(unlist(n_inputs)))

  expect_true("data" %in% names(hpc))
  expect_equal(hpc$data$iterate, "map")
  expect_equal(hpc$data$command, quote(readRDS(input_list)))
  expect_true("n_inputs" %in% names(hpc))
  expect_equal(hpc$n_inputs$iterate, "none")
  expect_equal(hpc$n_inputs$command, quote(length(sample_names)))
  expect_true("n_total" %in% names(hpc))
  expect_equal(hpc$n_total$command, quote(sum(unlist(n_inputs))))

  script <- readLines(paste0(store, ".R"))
  expect_true(any(grepl("target_output = \"data\"", script)))
  expect_true(any(grepl("quote\\(readRDS\\(input_list\\)\\)", script)))
  expect_false(any(grepl("data <- readRDS", script)))
  expect_true(any(grepl("other_arguments_to_map = \"input_list\"", script)))

  tt_evaluate(hpc)
  expect_equal(
    unname(targets::tar_read(data, store = store)[[1]]),
    1:3
  )
})

test_that("<- and target_output must name the same target", {
  tmp <- tempfile("tidytargets-")
  dir.create(tmp)
  old <- setwd(tmp)
  on.exit(setwd(old), add = TRUE)

  pipe <- tt_initialise(store = file.path(tmp, "store"))
  expect_no_error(tt_iterate(pipe, data <- 1, target_output = "data"))
  expect_error(
    tt_iterate(pipe, data <- 1, target_output = "other"),
    "different targets"
  )
  expect_error(
    tidytargets:::peel_assignment(quote(`<-`(foo$bar, 1))),
    "left-hand side"
  )
})

test_that("tt_data_list names the target from <-", {
  tmp <- tempfile("tidytargets-")
  dir.create(tmp)
  old <- setwd(tmp)
  on.exit(setwd(old), add = TRUE)

  pipe <- tt_initialise(store = file.path(tmp, "store")) |>
    tt_data_list(method_grid <- list(a = 1, b = 2))

  expect_true("method_grid" %in% names(pipe))
  expect_equal(pipe$method_grid$iterate, "map")
  expect_false(exists("method_grid", inherits = FALSE))
  expect_equal(
    names(qs2::qs_read(file.path(pipe$initialisation$store, "method_grid_data.qs"))),
    c("a", "b")
  )
})

test_that("tt_metadata reads, writes and survives pipeline steps", {
  tmp <- tempfile("tidytargets-")
  dir.create(tmp)
  old <- setwd(tmp)
  on.exit(setwd(old), add = TRUE)

  files <- c(sample_a = file.path(tmp, "a.rds"))
  saveRDS(1:3, files[[1]])

  store <- file.path(tmp, "store")
  hpc <- files |> tt_initialise(store = store)

  expect_equal(hpc |> tt_metadata(), list())

  hpc <- hpc |>
    tt_metadata(api_url = "https://api.example.org", api_version = 2L)

  expect_s3_class(hpc, "tidytargets")
  expect_equal(hpc |> tt_metadata() |> length(), 2)
  expect_equal(tt_metadata(hpc)$api_url, "https://api.example.org")

  # Metadata is preserved by, and does not interfere with, later steps
  hpc <- hpc |>
    tt_iterate(
      command = readRDS(input_list),
      target_output = "data"
    )

  expect_equal(tt_metadata(hpc)$api_version, 2L)
  expect_equal(hpc$data$iterate, "map")

  # Existing entries are updated, new ones merged, NULL removes
  hpc <- hpc |> tt_metadata(api_version = 3L, token = "abc")
  expect_equal(tt_metadata(hpc)$api_version, 3L)
  expect_equal(tt_metadata(hpc) |> names(), c("api_url", "api_version", "token"))

  hpc <- hpc |> tt_metadata(token = NULL)
  expect_false("token" %in% names(tt_metadata(hpc)))
})

test_that("tt_metadata rejects unnamed and duplicated entries", {
  tmp <- tempfile("tidytargets-")
  dir.create(tmp)
  old <- setwd(tmp)
  on.exit(setwd(old), add = TRUE)

  files <- c(sample_a = file.path(tmp, "a.rds"))
  saveRDS(1:3, files[[1]])

  hpc <- files |> tt_initialise(store = file.path(tmp, "store"))

  expect_error(hpc |> tt_metadata("https://api.example.org"), "must be named")
  expect_error(hpc |> tt_metadata(a = 1, a = 2), "unique")
})

test_that("metadata places no restriction on target names", {
  tmp <- tempfile("tidytargets-")
  dir.create(tmp)
  old <- setwd(tmp)
  on.exit(setwd(old), add = TRUE)

  files <- c(sample_a = file.path(tmp, "a.rds"))
  saveRDS(1:3, files[[1]])

  hpc <- files |>
    tt_initialise(store = file.path(tmp, "store")) |>
    tt_metadata(api_url = "https://api.example.org")

  # A target may be called "metadata"; the store is dot-prefixed and targets
  # forbids dot-prefixed target names, so the two cannot collide
  hpc <- hpc |>
    tt_iterate(
      command = readRDS(input_list),
      target_output = "metadata"
    )

  expect_equal(hpc$metadata$iterate, "map")
  expect_equal(tt_metadata(hpc)$api_url, "https://api.example.org")

  # The target is still resolvable as an upstream dependency
  hpc <- hpc |>
    tt_iterate(
      command = length(metadata),
      target_output = "downstream"
    )

  expect_equal(hpc$downstream$iterate, "map")
})

test_that("tt_report captures params as command-style symbols", {
  tmp <- tempfile("tidytargets-")
  dir.create(tmp)
  old <- setwd(tmp)
  on.exit(setwd(old), add = TRUE)

  files <- c(sample_a = file.path(tmp, "a.rds"))
  saveRDS(1:3, files[[1]])
  writeLines("n_samples: `r params$n_samples`", "example-report.qmd")

  store <- file.path(tmp, "store")
  hpc <- files |>
    tt_initialise(store = store) |>
    tt_single(
      command = length(sample_names),
      target_output = "n_samples"
    ) |>
    tt_report(
      target_output = "report",
      rmd_path = "example-report.qmd",
      params = list(n_samples = n_samples)
    )

  expect_s3_class(hpc, "tidytargets")
  expect_true("report" %in% names(hpc))
  expect_equal(hpc$report$iterate, "single")

  script <- readLines(paste0(store, ".R"))
  expect_true(any(grepl("n_samples = n_samples", script)))
  expect_false(any(grepl("is_target", script)))
})

test_that("tt_evaluate runs a pipeline and print is idempotent", {
  tmp <- tempfile("tidytargets-")
  dir.create(tmp)
  old <- setwd(tmp)
  on.exit(setwd(old), add = TRUE)

  inputs <- list(sample_a = 1:3, sample_b = 4:6)
  store <- file.path(tmp, "store")
  pipe <- inputs |>
    tt_initialise(store = store) |>
    tt_iterate(command = input_list * 2, target_output = "data")

  meta <- tt_evaluate(pipe)
  expect_s3_class(meta, "tbl_df")
  expect_true("data" %in% meta$name)

  values <- targets::tar_read(data, store = pipe$initialisation$store)
  expect_equal(unname(values), list(c(2, 4, 6), c(8, 10, 12)))

  # A second evaluate must not leave the script as a bare `target_list`
  meta2 <- tt_evaluate(pipe)
  expect_true("data" %in% meta2$name)
  script <- readLines(paste0(pipe$initialisation$store, ".R"))
  expect_true(any(grepl("target_list <- list", script)))
  expect_equal(sum(grepl("^\\s*target_list\\s*$", script)), 1L)
})

test_that("tt_evaluate uses store inputs after the working directory changes", {
  tmp <- tempfile("tidytargets-")
  dir.create(tmp)
  old <- setwd(tmp)
  on.exit(setwd(old), add = TRUE)

  pipe <- list(sample_a = 1:3, sample_b = 4:6) |>
    tt_initialise(store = "store") |>
    tt_iterate(command = input_list * 2, target_output = "data")

  setwd(old)
  on.exit(NULL)

  meta <- tt_evaluate(pipe)
  expect_true("data" %in% meta$name)
  values <- targets::tar_read(data, store = pipe$initialisation$store)
  expect_equal(unname(values), list(c(2, 4, 6), c(8, 10, 12)))
})

test_that("tt_evaluate appends the import_list hint to tar_make list-dispatch errors", {
  tmp <- tempfile("tidytargets-")
  dir.create(tmp)
  old <- setwd(tmp)
  on.exit(setwd(old), add = TRUE)

  pipe <- tt_initialise(store = file.path(tmp, "store")) |>
    tt_single(
      command = stop(
        "unable to find an inherited method for function ",
        "\u2018test_differential_expression\u2019 for signature ",
        "\u2018.data = \"list\"\u2019"
      ),
      target_output = "oops"
    )

  expect_error(tt_evaluate(pipe), "tt_data_list")
})

test_that("tt_explore returns one mapped instance and one stem target", {
  tmp <- tempfile("tidytargets-")
  dir.create(tmp)
  old <- setwd(tmp)
  on.exit(setwd(old), add = TRUE)

  pipe <- list(sample_a = 1:3, sample_b = 4:6) |>
    tt_initialise(store = file.path(tmp, "store")) |>
    tt_iterate(command = input_list * 2, target_output = "data") |>
    tt_single(command = length(sample_names), target_output = "n_inputs")

  expect_error(tt_explore(pipe, "missing"), "not a target")
  expect_error(tt_explore(pipe, 1), "target name")

  first <- NULL
  expect_message(
    first <- tt_explore(pipe, "data"),
    "instance 1 of 2",
    fixed = TRUE
  )
  expect_equal(first, c(2, 4, 6))

  unquoted <- NULL
  expect_message(
    unquoted <- tt_explore(pipe, data),
    "instance 1 of 2",
    fixed = TRUE
  )
  expect_equal(unquoted, c(2, 4, 6))

  second <- NULL
  expect_message(second <- tt_explore(pipe, "data", index = 2))
  expect_equal(second, c(8, 10, 12))

  expect_error(tt_explore(pipe, "data", index = 3), "out of range")

  piped <- NULL
  expect_message(
    piped <- tt_explore(pipe, "data") |> sum(),
    "instance 1 of 2",
    fixed = TRUE
  )
  expect_equal(piped, 12)

  n_inputs <- NULL
  expect_message(
    n_inputs <- tt_explore(pipe, "n_inputs"),
    "## n_inputs",
    fixed = TRUE
  )
  expect_equal(n_inputs, 2)

  input <- NULL
  expect_message(input <- tt_explore(pipe, "input_list"))
  expect_equal(input, 1:3)
})

test_that("tt_data snapshots a session object as a single stem target", {
  tmp <- tempfile("tidytargets-")
  dir.create(tmp)
  old <- setwd(tmp)
  on.exit(setwd(old), add = TRUE)

  airway <- list(counts = 1:5, meta = "demo")
  store <- file.path(tmp, "store")
  pipe <- list(sample_a = 1:3) |>
    tt_initialise(store = store) |>
    tt_data(airway, target_output = "airway")

  expect_s3_class(pipe, "tidytargets")
  expect_true("airway" %in% names(pipe))
  expect_true("airway_file" %in% names(pipe))
  expect_equal(pipe$airway$iterate, "none")
  expect_true(file.exists(file.path(store, "airway_data.qs")))
  expect_equal(qs2::qs_read(file.path(store, "airway_data.qs")), airway)

  pipe <- pipe |>
    tt_single(command = length(airway), target_output = "n_assays")

  expect_equal(pipe$n_assays$iterate, "none")

  tt_evaluate(pipe)
  expect_equal(
    targets::tar_read(airway, store = pipe$initialisation$store),
    airway
  )
  expect_equal(
    targets::tar_read(n_assays, store = pipe$initialisation$store),
    2
  )
})

test_that("tt_data defaults target_output to the object name", {
  tmp <- tempfile("tidytargets-")
  dir.create(tmp)
  old <- setwd(tmp)
  on.exit(setwd(old), add = TRUE)

  extra <- 10:12
  pipe <- list(sample_a = 1:3) |>
    tt_initialise(store = file.path(tmp, "store")) |>
    tt_data(extra)

  expect_true("extra" %in% names(pipe))
  expect_equal(pipe$extra$iterate, "none")
})

test_that("tt_data_list snapshots a list as mapped units", {
  tmp <- tempfile("tidytargets-")
  dir.create(tmp)
  old <- setwd(tmp)
  on.exit(setwd(old), add = TRUE)

  grid <- expand.grid(alpha = c(0, 1), lambda = c(0.1, 1))
  store <- file.path(tmp, "store")
  pipe <- tt_initialise(store = store) |>
    tt_data_list(
      grid |> split(seq_len(nrow(grid))),
      target_output = "settings"
    )

  expect_s3_class(pipe, "tidytargets")
  expect_true("settings" %in% names(pipe))
  expect_equal(pipe$settings$iterate, "map")
  saved <- qs2::qs_read(file.path(store, "settings_data.qs"))
  expect_equal(names(saved), c("1", "2", "3", "4"))

  pipe <- pipe |>
    tt_iterate(command = settings$alpha, target_output = "alpha")

  expect_equal(pipe$alpha$iterate, "map")
  script <- readLines(paste0(store, ".R"))
  expect_true(any(grepl("other_arguments_to_map = \"settings\"", script)))

  tt_evaluate(pipe)
  values <- targets::tar_read(alpha, store = pipe$initialisation$store)
  expect_equal(unname(unlist(values)), grid$alpha)
})

test_that("tt_data_list defaults target_output to the object name", {
  tmp <- tempfile("tidytargets-")
  dir.create(tmp)
  old <- setwd(tmp)
  on.exit(setwd(old), add = TRUE)

  rows <- list(a = 1:2, b = 3:4)
  pipe <- tt_initialise(store = file.path(tmp, "store")) |>
    tt_data_list(rows)

  expect_true("rows" %in% names(pipe))
  expect_equal(pipe$rows$iterate, "map")
})

test_that("tt_data_list rejects a non-list and an unnamed expression", {
  tmp <- tempfile("tidytargets-")
  dir.create(tmp)
  old <- setwd(tmp)
  on.exit(setwd(old), add = TRUE)

  pipe <- tt_initialise(store = file.path(tmp, "store"))
  expect_error(tt_data_list(pipe, 1:3, target_output = "x"), "expects a list")
  expect_error(
    tt_data_list(pipe, list(1, 2)),
    "target_output"
  )
})

test_that("tt_initialise snapshots attached package names, not session objects", {
  tmp <- tempfile("tidytargets-")
  dir.create(tmp)
  old <- setwd(tmp)
  on.exit(setwd(old), add = TRUE)

  was_attached <- "glue" %in% .packages()
  if (!was_attached) {
    library(glue)
    on.exit(detach("package:glue", character.only = TRUE), add = TRUE)
  }

  assign("local_blob", list(x = 1:100), envir = .GlobalEnv)
  on.exit(rm("local_blob", envir = .GlobalEnv), add = TRUE)

  store <- file.path(tmp, "store")
  pipe <- tt_initialise(store = store)
  script <- paste(readLines(paste0(store, ".R")), collapse = "\n")

  expect_true("glue" %in% pipe$initialisation$packages)
  expect_match(script, '"glue"')
  expect_false(grepl("local_blob", script))
})

test_that("tt_initialise packages= overrides the attached snapshot", {
  tmp <- tempfile("tidytargets-")
  dir.create(tmp)
  old <- setwd(tmp)
  on.exit(setwd(old), add = TRUE)

  was_attached <- "glue" %in% .packages()
  if (!was_attached) {
    library(glue)
    on.exit(detach("package:glue", character.only = TRUE), add = TRUE)
  }

  store <- file.path(tmp, "store")
  pipe <- tt_initialise(store = store, packages = "tidytargets")
  script <- paste(readLines(paste0(store, ".R")), collapse = "\n")

  expect_equal(pipe$initialisation$packages, "tidytargets")
  expect_false(grepl('"glue"', script))
})

test_that("explicit packages on a target is not overwritten by attached packages", {
  tmp <- tempfile("tidytargets-")
  dir.create(tmp)
  old <- setwd(tmp)
  on.exit(setwd(old), add = TRUE)

  was_attached <- "glue" %in% .packages()
  if (!was_attached) {
    library(glue)
    on.exit(detach("package:glue", character.only = TRUE), add = TRUE)
  }

  store <- file.path(tmp, "store")
  pipe <- tt_initialise(store = store, packages = "tidytargets") |>
    tt_single(n <- 1, packages = "qs2")

  script <- readLines(paste0(store, ".R"))
  factory_line <- script[grepl("target_output = \"n\"", script)]
  expect_length(factory_line, 1L)
  expect_match(factory_line, 'packages = "qs2"')
  expect_false(grepl("glue", factory_line))
})

test_that("unqualified functions from attached packages run on workers", {
  tmp <- tempfile("tidytargets-")
  dir.create(tmp)
  old <- setwd(tmp)
  on.exit(setwd(old), add = TRUE)

  was_attached <- "glue" %in% .packages()
  if (!was_attached) {
    library(glue)
    on.exit(detach("package:glue", character.only = TRUE), add = TRUE)
  }

  store <- file.path(tmp, "store")
  pipe <- tt_initialise(store = store) |>
    tt_single(msg <- glue("hi"))
  tt_evaluate(pipe)
  expect_equal(
    as.character(targets::tar_read(msg, store = pipe$initialisation$store)),
    "hi"
  )
})
