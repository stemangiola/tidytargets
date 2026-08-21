# tidytargets

A tidy, pipe-friendly grammar for `{targets}`, internally based on [targets factories](https://books.ropensci.org/targets/static.html#target-factories).

Compose pipelines with pipes (`|>`) and run them locally, on HPC, or in the cloud. `tt_initialise()` constructs a `tidytargets` object; `tt_iterate()`, `tt_single()`, `tt_merge()`, `tt_report()`, and `tt_evaluate()` are methods on that class. Those calls are factories that write a `{targets}` dependency graph. Compute backends (for example `{crew}` or `{crew.cluster}`) are optional and passed in at `tt_initialise()`.

The grammar is **lazy** and **incremental**. Piping steps only appends factories to the targets script; nothing is computed until `tt_evaluate()` (or printing the object). You can add inputs or steps later and `{targets}` re-runs only the outdated branches of the graph.

## Installation

``` r
remotes::install_github("MangiolaLaboratory/tidytargets")
```

A full walkthrough of every grammar function, with the `{targets}` script each step writes, is in the vignette:

``` r
vignette("building-blocks", package = "tidytargets")
```

## A minimal pipeline

`tt_initialise()` takes a named vector of inputs (typically file paths). Use `is_target()` to point a step at an upstream target. With no `computing_resources`, the pipeline runs sequentially.

``` r
library(tidytargets)

files <- c(
  sample_a = "a.rds",
  sample_b = "b.rds"
)

files |>
  tt_initialise(store = "_targets") |>
  tt_iterate(
    target_output = "data",
    user_function = readRDS |> quote(),
    file = "input_list" |> is_target()
  ) |>
  tt_iterate(
    target_output = "summaries",
    user_function = summary |> quote(),
    object = "data" |> is_target()
  ) |>
  tt_evaluate()
```

`tt_initialise()` registers two mapped targets for you:

- `input_list` — the named input vector
- `sample_names` — the names of that vector

## Grammar

| Function | Role |
| --- | --- |
| `tt_initialise()` | Start a pipeline: store, optional controller, tiers |
| `tt_iterate()` | Map a function over inputs (and optional tiers) |
| `tt_single()` | Add one non-iterated target |
| `tt_merge()` | Combine iterated results into one object |
| `tt_report()` | Render a Quarto / R Markdown report |
| `tt_evaluate()` | Write the target list and run `tar_make()` |
| `is_target()` | Mark an argument as an upstream target name |

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

### Tiers

Assign inputs to resource tiers so large jobs use a different named controller. The controller names must match the `tier` labels.

``` r
computing_resources <- crew::crew_controller_group(
  crew::crew_controller_local(name = "1", workers = 4),
  crew::crew_controller_local(name = "2", workers = 10)
)

tt_initialise(
  files,
  tier = c(1, 1, 2),
  computing_resources = computing_resources
)
```
