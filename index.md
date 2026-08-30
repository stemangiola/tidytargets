# tidytargets

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
(mapped units). Write `name <- expr` to name the target from the
assignment, the same way you would write a `tar_target()` command;
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

| Function | Role |
|----|----|
| [`tt_initialise()`](https://stemangiola.github.io/tidytargets/reference/tt_initialise.md) | Start a pipeline: store, optional mapped inputs |
| [`tt_data()`](https://stemangiola.github.io/tidytargets/reference/tt_data.md) | Snapshot a session object onto the store as one target |
| [`tt_data_list()`](https://stemangiola.github.io/tidytargets/reference/tt_data_list.md) | Snapshot a list onto the store as mapped units |
| [`tt_iterate()`](https://stemangiola.github.io/tidytargets/reference/tt_iterate.md) | Map or cross a function over mapped inputs |
| [`tt_single()`](https://stemangiola.github.io/tidytargets/reference/tt_single.md) | Add one non-iterated target |
| [`tt_merge()`](https://stemangiola.github.io/tidytargets/reference/tt_merge.md) | Combine iterated results into one object |
| [`tt_report()`](https://stemangiola.github.io/tidytargets/reference/tt_report.md) | Render a Quarto / R Markdown report |
| [`tt_evaluate()`](https://stemangiola.github.io/tidytargets/reference/tt_evaluate.md) | Write the target list and run `tar_make()` |
| [`tt_explore()`](https://stemangiola.github.io/tidytargets/reference/tt_explore.md) | Return one stored instance of a named target |
| [`tt_metadata()`](https://stemangiola.github.io/tidytargets/reference/tt_metadata.md) | Get or set free-form metadata on the pipeline object |

## Carrying extra information

A `tidytargets` object is a named list: `$initialisation` holds the
arguments given to
[`tt_initialise()`](https://stemangiola.github.io/tidytargets/reference/tt_initialise.md),
and every other element is a target you added. Alongside those sits a
free-form metadata store, reachable only through
[`tt_metadata()`](https://stemangiola.github.io/tidytargets/reference/tt_metadata.md),
for information that is not part of the graph — an API endpoint, a
dataset identifier, a provenance note.

`pipeline`` ``<-`` `[`tt_initialise`](https://stemangiola.github.io/tidytargets/reference/tt_initialise.md)`(``)`` ``|>`` `` `[`tt_metadata`](https://stemangiola.github.io/tidytargets/reference/tt_metadata.md)`(``api_url ``=`` ``"https://api.example.org"``, api_version ``=`` ``2``)`` `` `[`tt_metadata`](https://stemangiola.github.io/tidytargets/reference/tt_metadata.md)`(``pipeline``)``$``api_url`` ``#> [1] "https://api.example.org"`

Metadata is merged on each call, and passing `NULL` removes an entry. It
travels with the object through every grammar step but is not written to
the targets script, so workers cannot see it; values a target needs must
appear in `command`. The store is inert with respect to the rest of the
grammar and constrains nothing — it imposes no restriction on your
`target_output` names.

## Deployment

Pass any controller that `targets::tar_option_set(controller = )`
accepts. tidytargets does not import a backend.

### Local parallel computing

`computing_resources`` ``<-`` ``crew``::`[`crew_controller_local`](https://wlandau.github.io/crew/reference/crew_controller_local.html)`(``workers ``=`` ``10``)`

Pass this to `tt_initialise(computing_resources = ...)`.

### SLURM

`computing_resources`` ``<-`` ``crew.cluster``::`[`crew_controller_slurm`](https://wlandau.github.io/crew.cluster/reference/crew_controller_slurm.html)`(`` `` workers ``=`` ``50``,`` `` tasks_max ``=`` ``1``,`` `` seconds_idle ``=`` ``30``,`` `` options_cluster ``=`` ``crew.cluster``::`[`crew_options_slurm`](https://wlandau.github.io/crew.cluster/reference/crew_options_slurm.html)`(`` `` partition ``=`` ``"standard"`` `` ``)`` ``)`
