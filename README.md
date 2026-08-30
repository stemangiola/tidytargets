# tidytargets

A tidy, pipe-friendly grammar for `{targets}`, internally based on [targets factories](https://books.ropensci.org/targets/static.html#target-factories).

Compose pipelines with pipes (`|>`) and run them locally, on HPC, or in the cloud. `tt_initialise()` constructs a `tidytargets` object; `tt_iterate()`, `tt_single()`, `tt_merge()`, `tt_report()`, and `tt_evaluate()` are methods on that class. Those calls are factories that write a `{targets}` dependency graph. Compute backends (for example `{crew}` or `{crew.cluster}`) are optional and passed in at `tt_initialise()`.

The grammar is **lazy** and **incremental**. Piping steps only appends factories to the targets script; nothing is computed until `tt_evaluate()` (or evaluating the object; e.g., printing it in the console). Assigning the object does not print it, so an interactive session then says the pipeline is ready to be evaluated, rather than appearing to do nothing. You can add inputs or steps later and `{targets}` re-runs only the outdated branches of the graph.

## Installation

``` r
remotes::install_github("stemangiola/tidytargets")
```

A full walkthrough of every grammar function, with the `{targets}` script each step writes, is in the vignette:

``` r
vignette("building-blocks", package = "tidytargets")
```

## A minimal pipeline

`tt_initialise()` starts a pipeline (store and optional `computing_resources`). Bring session objects in with `tt_data()` (one target) or `tt_data_list()` (mapped units). Write `name <- expr` to name the target from the assignment, the same way you would write a `tar_target()` command; `{targets}` tracks upstream names in that expression. `target_output = "name"` still works. With no `computing_resources`, the pipeline runs sequentially. With no `store`, a unique `./tidytargets-<HASH>` directory is created and printed.

``` r
library(tidytargets)

inputs <- list(
  sample_a = 1:3,
  sample_b = 4:6
)

tt_initialise() |>
  tt_data_list(inputs) |>
  tt_iterate(summaries <- summary(inputs)) |>
  tt_evaluate()
```
```
#> + inputs_file dispatched
#> ✔ inputs_file completed [0ms, 187 B]
#> + inputs dispatched
#> ✔ inputs completed [0ms, 187 B]
#> + summaries declared [2 branches]
#> ✔ summaries completed [1ms, 392 B]
#> ✔ ended pipeline [86ms, 4 completed, 0 skipped]

targets::tar_read(summaries, store = "_targets")
#> $summaries_6e3ea80794aeb114
#>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max.
#>     1.0     1.5     2.0     2.0     2.5     3.0
#>
#> $summaries_629826fd23b4f282
#>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max.
#>     4.0     4.5     5.0     5.0     5.5     6.0
```

`tt_evaluate()` also returns the `targets::tar_meta()` table. `tt_data_list()` registers the named list as a mapped target (`inputs` here); later `tt_iterate()` steps that mention it are mapped over each element.

## Grammar

| Function | Role |
| --- | --- |
| `tt_initialise()` | Start a pipeline: store, optional mapped inputs |
| `tt_data()` | Snapshot a session object onto the store as one target |
| `tt_data_list()` | Snapshot a list onto the store as mapped units |
| `tt_iterate()` | Map or cross a function over mapped inputs |
| `tt_single()` | Add one non-iterated target |
| `tt_merge()` | Combine iterated results into one object |
| `tt_report()` | Render a Quarto / R Markdown report |
| `tt_evaluate()` | Write the target list and run `tar_make()` |
| `tt_explore()` | Return one stored instance of a named target |
| `tt_metadata()` | Get or set free-form metadata on the pipeline object |

## Carrying extra information

A `tidytargets` object has three slots: `$initialisation` (the arguments given to `tt_initialise()`), `$metadata` (free-form extras, also reachable through `tt_metadata()`), and `$targets` (one named record per target you added). Metadata is for information that is not part of the graph — an API endpoint, a dataset identifier, a provenance note.

``` r
pipeline <- tt_initialise() |>
  tt_metadata(api_url = "https://api.example.org", api_version = 2)

tt_metadata(pipeline)$api_url
#> [1] "https://api.example.org"
```

Metadata is merged on each call, and passing `NULL` removes an entry. It travels with the object through every grammar step but is not written to the targets script, so workers cannot see it; values a target needs must appear in `command`. Because it lives in `$metadata` rather than among the steps, it imposes no restriction on your `target_output` names.

## Deployment

Pass any controller that `targets::tar_option_set(controller = )` accepts. tidytargets does not import a backend.

### Local parallel computing

``` r
computing_resources <- crew::crew_controller_local(workers = 10)
```

Pass this to `tt_initialise(computing_resources = ...)`.

### SLURM

``` r
computing_resources <- crew.cluster::crew_controller_slurm(
  workers = 50,
  tasks_max = 1,
  seconds_idle = 30,
  options_cluster = crew.cluster::crew_options_slurm(
    partition = "standard"
  )
)
```
