# tidytargets

Compose `{targets}` pipelines with pipes (`|>`) and run them locally, on HPC, or in the cloud.

`tidytargets` is a tidy grammar for the [targets](https://docs.ropensci.org/targets/) workflow manager. You describe steps with `hpc_iterate()`, `hpc_single()`, `hpc_merge()`, and `hpc_report()`; the package writes a dependency graph that `{targets}` executes. Compute backends (for example `{crew}` or `{crew.cluster}`) are optional and passed in at `initialise_hpc()`.

## Installation

``` r
remotes::install_github("MangiolaLaboratory/tidytargets")
```

## A minimal pipeline

`initialise_hpc()` takes a named vector of inputs (typically file paths). Use `is_target()` to point a step at an upstream target. With no `computing_resources`, the pipeline runs sequentially.

``` r
library(tidytargets)

files <- c(
  sample_a = "a.rds",
  sample_b = "b.rds"
)

files |>
  initialise_hpc(store = "_targets") |>
  hpc_iterate(
    target_output = "data",
    user_function = readRDS |> quote(),
    file = "input_list" |> is_target()
  ) |>
  hpc_iterate(
    target_output = "summaries",
    user_function = summary |> quote(),
    object = "data" |> is_target()
  ) |>
  evaluate_hpc()
```

`initialise_hpc()` registers two mapped targets for you:

- `input_list` — the named input vector
- `sample_names` — the names of that vector

## Grammar

| Function | Role |
| --- | --- |
| `initialise_hpc()` | Start a pipeline: store, optional controller, tiers |
| `hpc_iterate()` | Map a function over inputs (and optional tiers) |
| `hpc_single()` | Add one non-iterated target |
| `hpc_merge()` | Combine iterated results into one object |
| `hpc_report()` | Render a Quarto / R Markdown report |
| `evaluate_hpc()` | Write the target list and run `tar_make()` |
| `is_target()` | Mark an argument as an upstream target name |

## Deployment

Pass any controller that `targets::tar_option_set(controller = )` accepts. tidytargets does not import a backend.

### Local parallel computing

``` r
computing_resources <- crew::crew_controller_local(workers = 10)
```

Pass this to `initialise_hpc(computing_resources = ...)`.

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

initialise_hpc(
  files,
  tier = c(1, 1, 2),
  computing_resources = computing_resources
)
```
