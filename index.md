# tidytargets (alpha)

A tidy, pipe-friendly grammar for
[targets](https://docs.ropensci.org/targets/), internally based on
[targets
factories](https://books.ropensci.org/targets/static.html#target-factories).

Compose pipelines with pipes (`|>`) and run them locally, on HPC, or in
the cloud.
[`tt_initialise()`](https://stemangiola.github.io/tidytargets/reference/tt_initialise.md)
constructs a `tidytargets` object;
[`tt_iterate()`](https://stemangiola.github.io/tidytargets/reference/tt_iterate.md),
[`tt_single()`](https://stemangiola.github.io/tidytargets/reference/tt_single.md),
[`tt_split()`](https://stemangiola.github.io/tidytargets/reference/tt_split.md),
[`tt_merge()`](https://stemangiola.github.io/tidytargets/reference/tt_merge.md),
[`tt_report()`](https://stemangiola.github.io/tidytargets/reference/tt_report.md),
and
[`tt_evaluate()`](https://stemangiola.github.io/tidytargets/reference/tt_evaluate.md)
are methods on that class. Those calls are factories that write a
[targets](https://docs.ropensci.org/targets/) dependency graph. Compute
backends (for example [crew](https://wlandau.github.io/crew/) or
[crew.cluster](https://wlandau.github.io/crew.cluster/)) are optional
and passed in at
[`tt_initialise()`](https://stemangiola.github.io/tidytargets/reference/tt_initialise.md).

The grammar is **lazy** and **incremental**. Piping steps only appends
factories to the targets script; nothing is computed until
[`tt_evaluate()`](https://stemangiola.github.io/tidytargets/reference/tt_evaluate.md)
(or evaluating the object; e.g., printing it in the console). Assigning
the object does not print it, so an interactive session then says the
pipeline is ready to be evaluated, rather than appearing to do nothing.
You can add inputs or steps later and
[targets](https://docs.ropensci.org/targets/) re-runs only the outdated
branches of the graph.

## Installation

`remotes``::`[`install_github`](https://remotes.r-lib.org/reference/install_github.html)`(``"stemangiola/tidytargets"``)`

A full walkthrough of every grammar function, with the
[targets](https://docs.ropensci.org/targets/) script each step writes,
is in the vignette:

[`vignette`](https://rdrr.io/r/utils/vignette.html)`(``"building-blocks"``, package ``=`` ``"tidytargets"``)`

## A minimal pipeline

[`tt_initialise()`](https://stemangiola.github.io/tidytargets/reference/tt_initialise.md)
starts a pipeline (store and optional `computing_resources`). Bring
session objects in with
[`tt_data()`](https://stemangiola.github.io/tidytargets/reference/tt_data.md)
(one target) or
[`tt_data_list()`](https://stemangiola.github.io/tidytargets/reference/tt_data_list.md)
(mapped units), and helper functions with
[`tt_global()`](https://stemangiola.github.io/tidytargets/reference/tt_global.md).
Write `name <- expr` to name the target from the assignment, the same
way you would write a `tar_target()` command;
[targets](https://docs.ropensci.org/targets/) tracks upstream names in
that expression. `target_output = "name"` still works. With no
`computing_resources`, the pipeline runs sequentially. With no `store`,
a unique `./tidytargets-<HASH>` directory is created and printed.

[`library`](https://rdrr.io/r/base/library.html)`(`[`tidytargets`](https://stemangiola.github.io/tidytargets/)`)`` `` ``inputs`` ``<-`` `[`list`](https://rdrr.io/r/base/list.html)`(`` `` sample_a ``=`` ``1``:``3``,`` `` sample_b ``=`` ``4``:``6`` ``)`` `` `[`tt_initialise`](https://stemangiola.github.io/tidytargets/reference/tt_initialise.md)`(``)`` ``|>`` `` `[`tt_data_list`](https://stemangiola.github.io/tidytargets/reference/tt_data_list.md)`(``inputs``)`` ``|>`` `` `[`tt_iterate`](https://stemangiola.github.io/tidytargets/reference/tt_iterate.md)`(``summaries`` ``<-`` `[`summary`](https://rdrr.io/r/base/summary.html)`(``inputs``)``)`` ``|>`` `` `[`tt_evaluate`](https://stemangiola.github.io/tidytargets/reference/tt_evaluate.md)`(``)`

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

[`tt_evaluate()`](https://stemangiola.github.io/tidytargets/reference/tt_evaluate.md)
also returns the
[`targets::tar_meta()`](https://docs.ropensci.org/targets/reference/tar_meta.html)
table.
[`tt_data_list()`](https://stemangiola.github.io/tidytargets/reference/tt_data_list.md)
registers the named list as a mapped target (`inputs` here); later
[`tt_iterate()`](https://stemangiola.github.io/tidytargets/reference/tt_iterate.md)
steps that mention it are mapped over each element.

## Grammar

### Workflow

| Function | Role |
|----|----|
| [`tt_initialise()`](https://stemangiola.github.io/tidytargets/reference/tt_initialise.md) | Start a pipeline: store, optional mapped inputs |
| [`tt_evaluate()`](https://stemangiola.github.io/tidytargets/reference/tt_evaluate.md) | Write the target list and run `tar_make()` |
| [`tt_script()`](https://stemangiola.github.io/tidytargets/reference/tt_script.md) | Write the target list without running it, for inspection |
| [`tt_read()`](https://stemangiola.github.io/tidytargets/reference/tt_read.md) | Read the full stored value of a named target |

### Data

| Function | Role |
|----|----|
| [`tt_data()`](https://stemangiola.github.io/tidytargets/reference/tt_data.md) | Snapshot a session object onto the store as one target |
| [`tt_data_list()`](https://stemangiola.github.io/tidytargets/reference/tt_data_list.md) | Snapshot a list onto the store as mapped units |
| [`tt_global()`](https://stemangiola.github.io/tidytargets/reference/tt_global.md) | Declare helper functions every target can call |
| [`tt_merge()`](https://stemangiola.github.io/tidytargets/reference/tt_merge.md) | Combine iterated results into one object |
| [`tt_split()`](https://stemangiola.github.io/tidytargets/reference/tt_split.md) | Turn a pipeline list into mapped units |

### Commands

| Function | Role |
|----|----|
| [`tt_iterate()`](https://stemangiola.github.io/tidytargets/reference/tt_iterate.md) | Map or cross a function over mapped inputs |
| [`tt_single()`](https://stemangiola.github.io/tidytargets/reference/tt_single.md) | Add one non-iterated target |

### Reporting and debugging

| Function | Role |
|----|----|
| [`tt_report()`](https://stemangiola.github.io/tidytargets/reference/tt_report.md) | Render a Quarto / R Markdown report |
| [`tt_explore()`](https://stemangiola.github.io/tidytargets/reference/tt_explore.md) | Return one stored instance of a named target |
| [`tt_metadata()`](https://stemangiola.github.io/tidytargets/reference/tt_metadata.md) | Get or set free-form metadata on the pipeline object |

## Inspecting the graph before running it

Composing a pipeline only builds an object; `{store}.R` is generated
from it when the pipeline runs. Call
[`tt_script()`](https://stemangiola.github.io/tidytargets/reference/tt_script.md)
to write the script early and register it with
[`targets::tar_config_set()`](https://docs.ropensci.org/targets/reference/tar_config_set.html),
after which the [targets](https://docs.ropensci.org/targets/) inspection
functions work with no arguments:

`pipe`` ``<-`` `[`tt_initialise`](https://stemangiola.github.io/tidytargets/reference/tt_initialise.md)`(``)`` ``|>`` `` `[`tt_data_list`](https://stemangiola.github.io/tidytargets/reference/tt_data_list.md)`(``inputs``)`` ``|>`` `` `[`tt_iterate`](https://stemangiola.github.io/tidytargets/reference/tt_iterate.md)`(``summaries`` ``<-`` `[`summary`](https://rdrr.io/r/base/summary.html)`(``inputs``)``)`` `` `[`tt_script`](https://stemangiola.github.io/tidytargets/reference/tt_script.md)`(``pipe``)`` `` ``targets``::`[`tar_manifest`](https://docs.ropensci.org/targets/reference/tar_manifest.html)`(``)`` ``# one row per target`` ``targets``::`[`tar_outdated`](https://docs.ropensci.org/targets/reference/tar_outdated.html)`(``)`` ``# what a run would rebuild`` ``targets``::`[`tar_visnetwork`](https://docs.ropensci.org/targets/reference/tar_visnetwork.html)`(``)`` ``# the dependency graph`

Nothing is executed until
[`tt_evaluate()`](https://stemangiola.github.io/tidytargets/reference/tt_evaluate.md).
Use
[`show_targets_script()`](https://stemangiola.github.io/tidytargets/reference/show_targets_script.md)
to read the generated script instead of inspecting the graph.

## Deployment

Pass any controller that `targets::tar_option_set(controller = )`
accepts.

### Local parallel computing

`computing_resources`` ``<-`` ``crew``::`[`crew_controller_local`](https://wlandau.github.io/crew/reference/crew_controller_local.html)`(``workers ``=`` ``10``)`

Pass this to `tt_initialise(computing_resources = ...)`.

### SLURM

`computing_resources`` ``<-`` ``crew.cluster``::`[`crew_controller_slurm`](https://wlandau.github.io/crew.cluster/reference/crew_controller_slurm.html)`(`` `` workers ``=`` ``100``,`` `` tasks_max ``=`` ``1``,`` `` seconds_idle ``=`` ``30``,`` `` options_cluster ``=`` ``crew.cluster``::`[`crew_options_slurm`](https://wlandau.github.io/crew.cluster/reference/crew_options_slurm.html)`(`` `` partition ``=`` ``"standard"`` `` ``)`` ``)`

### Elastic SLURM (auto-scaling tiers)

[`tt_controller_elastic_slurm()`](https://stemangiola.github.io/tidytargets/reference/tt_controller_elastic_slurm.md)
wraps several
[`crew.cluster::crew_controller_slurm()`](https://wlandau.github.io/crew.cluster/reference/crew_controller_slurm.html)
resource tiers, sized from small to large, into a
[`crew::crew_controller_group()`](https://wlandau.github.io/crew/reference/crew_controller_group.html).
A tier automatically falls back to the next tier up once its workers
exhaust `crashes_max` (for example, once a job runs out of memory), so
most jobs run on cheap, small workers while a few fall through to
progressively larger ones. [crew](https://wlandau.github.io/crew/) and
[crew.cluster](https://wlandau.github.io/crew.cluster/) are not
dependencies of tidytargets; install them yourself to use this wrapper.

Tiers are ordered smallest to largest; tier names are generated
automatically from `mem_gb_per_job` (e.g. `5` becomes `"elastic_5"`).
`time_hours` is the lifetime of a worker (a SLURM job), not the run time
of one target: a worker stays alive to run multiple targets back to back
until `time_hours` elapses, at which point SLURM kills it — along with
whatever target it happens to be running — and
[crew](https://wlandau.github.io/crew/) relaunches that target on a
brand new worker. Set it as long as practical so a worker survives as
many targets as possible, and always longer than the longest single
target it may run.

`workers` and `mem_gb_per_job` are required. Every other argument may be
a single value, which is recycled to every tier, or a vector with one
value per tier. So the minimal call only needs `workers` and
`mem_gb_per_job`, with `time_hours = 24`, `crashes_max = 2`, and
`cpus_per_task = 1` applied to every tier:

`computing_resources`` ``<-`` `[`tt_controller_elastic_slurm`](https://stemangiola.github.io/tidytargets/reference/tt_controller_elastic_slurm.md)`(`` `` workers ``=`` ``100``,`` `` mem_gb_per_job ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``5``, ``10``, ``20``, ``50``, ``100``)`` ``)`

Pass this to `tt_initialise(computing_resources = ...)`.

### Pinning a step to a named tier

Any controller group makes its tiers available by name. A step with no
`resources` runs on the first tier and falls back as described above;
pass `resources` to send a step straight to a chosen tier, using the
[targets](https://docs.ropensci.org/targets/) syntax:

[`tt_initialise`](https://stemangiola.github.io/tidytargets/reference/tt_initialise.md)`(``computing_resources ``=`` ``computing_resources``)`` ``|>`` `` `[`tt_iterate`](https://stemangiola.github.io/tidytargets/reference/tt_iterate.md)`(``counts`` ``<-`` ``load_counts``(``input_list``)``)`` ``|>`` `` `[`tt_single`](https://stemangiola.github.io/tidytargets/reference/tt_single.md)`(`` `` ``model`` ``<-`` ``fit``(``counts``)``,`` `` resources ``=`` ``tar_resources``(``crew ``=`` ``tar_resources_crew``(``controller ``=`` ``"elastic_100"``)``)`` `` ``)`

The `tar_resources()` call is written into `{store}.R` and evaluated
there, next to the controller group it names. Write it where the step is
declared: an object built beforehand holds an environment, so it cannot
be written into a script, and `tidytargets` says so rather than leaving
you a broken one.
