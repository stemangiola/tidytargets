# tidytargets (alpha)

A tidy, pipe-friendly grammar for `{targets}`, internally based on [targets factories](https://books.ropensci.org/targets/static.html#target-factories).

Compose pipelines with pipes (`|>`) and run them locally, on HPC, or in the cloud. `tt_initialise()` constructs a `tidytargets` object; `tt_iterate()`, `tt_single()`, `tt_split()`, `tt_merge()`, `tt_report()`, and `tt_evaluate()` are methods on that class. Those calls are factories that write a `{targets}` dependency graph. Compute backends (for example `{crew}` or `{crew.cluster}`) are optional and passed in at `tt_initialise()`.

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

`tt_initialise()` starts a pipeline (store and optional `computing_resources`). Bring session objects in with `tt_data()` (one target) or `tt_data_list()` (mapped units), and helper functions with `tt_global()`. Write `name <- expr` to name the target from the assignment, the same way you would write a `tar_target()` command; `{targets}` tracks upstream names in that expression. `target_output = "name"` still works. With no `computing_resources`, the pipeline runs sequentially. With no `store`, a unique `./tidytargets-<HASH>` directory is created and printed.

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

### Workflow

| Function | Role |
| --- | --- |
| `tt_initialise()` | Start a pipeline: store, optional mapped inputs |
| `tt_evaluate()` | Write the target list and run `tar_make()` |
| `tt_script()` | Write the target list without running it, for inspection |
| `tt_read()` | Read the full stored value of a named target |

### Data

| Function | Role |
| --- | --- |
| `tt_data()` | Snapshot a session object onto the store as one target |
| `tt_data_list()` | Snapshot a list onto the store as mapped units |
| `tt_global()` | Declare helper functions every target can call |
| `tt_merge()` | Combine iterated results into one object |
| `tt_split()` | Turn a pipeline list into mapped units |

### Commands

| Function | Role |
| --- | --- |
| `tt_iterate()` | Map or cross a function over mapped inputs |
| `tt_single()` | Add one non-iterated target |

### Reporting and debugging

| Function | Role |
| --- | --- |
| `tt_report()` | Render a Quarto / R Markdown report |
| `tt_explore()` | Return one stored instance of a named target |
| `tt_metadata()` | Get or set free-form metadata on the pipeline object |

## Inspecting the graph before running it

Composing a pipeline only builds an object; `{store}.R` is generated from it
when the pipeline runs. Call `tt_script()` to write the script early and
register it with `targets::tar_config_set()`, after which the `{targets}`
inspection functions work with no arguments:

``` r
pipe <- tt_initialise() |>
  tt_data_list(inputs) |>
  tt_iterate(summaries <- summary(inputs))

tt_script(pipe)

targets::tar_manifest()    # one row per target
targets::tar_outdated()    # what a run would rebuild
targets::tar_visnetwork()  # the dependency graph
```

Nothing is executed until `tt_evaluate()`. Use `show_targets_script()` to
read the generated script instead of inspecting the graph.

## Deployment

Pass any controller that `targets::tar_option_set(controller = )` accepts. 

### Local parallel computing

``` r
computing_resources <- crew::crew_controller_local(workers = 10)
```

Pass this to `tt_initialise(computing_resources = ...)`.

### SLURM

``` r
computing_resources <- crew.cluster::crew_controller_slurm(
  workers = 100,
  tasks_max = 1,
  seconds_idle = 30,
  options_cluster = crew.cluster::crew_options_slurm(
    partition = "standard"
  )
)
```

### Elastic SLURM (auto-scaling tiers)

`tt_controller_elastic_slurm()` wraps several `crew.cluster::crew_controller_slurm()`
resource tiers, sized from small to large, into a `crew::crew_controller_group()`.
A tier automatically falls back to the next tier up once its workers exhaust
`crashes_max` (for example, once a job runs out of memory), so most jobs run
on cheap, small workers while a few fall through to progressively larger ones.
`{crew}` and `{crew.cluster}` are not dependencies of tidytargets; install them
yourself to use this wrapper.

Tiers are ordered smallest to largest; tier names are generated automatically
from `mem_gb_per_job` (e.g. `5` becomes `"elastic_5"`). `time_hours` is the
lifetime of a worker (a SLURM job), not the run time of one target: a worker
stays alive to run multiple targets back to back until `time_hours` elapses,
at which point SLURM kills it — along with whatever target it happens to be
running — and `{crew}` relaunches that target on a brand new worker. Set it
as long as practical so a worker survives as many targets as possible, and
always longer than the longest single target it may run.

`workers` and `mem_gb_per_job` are required. Every other argument may be a
single value, which is recycled to every tier, or a vector with one value
per tier. So the minimal call only needs `workers` and `mem_gb_per_job`,
with `time_hours = 24`, `crashes_max = 2`, and `cpus_per_task = 1` applied
to every tier:

``` r
computing_resources <- tt_controller_elastic_slurm(
  workers = 100,
  mem_gb_per_job = c(5, 10, 20, 50, 100)
)
```

Pass this to `tt_initialise(computing_resources = ...)`.

### Pinning a step to a named tier

Any controller group makes its tiers available by name. A step with no
`resources` runs on the first tier and falls back as described above; pass
`resources` to send a step straight to a chosen tier, using the `{targets}`
syntax:

``` r
tt_initialise(computing_resources = computing_resources) |>
  tt_iterate(counts <- load_counts(input_list)) |>
  tt_single(
    model <- fit(counts),
    resources = tar_resources(crew = tar_resources_crew(controller = "elastic_100"))
  )
```

The `tar_resources()` call is written into `{store}.R` and evaluated there,
next to the controller group it names. Write it where the step is declared: an
object built beforehand holds an environment, so it cannot be written into a
script, and `tidytargets` says so rather than leaving you a broken one.
