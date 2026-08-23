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
(or evaluating the object; e.g., printing it in the console). You can
add inputs or steps later and
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
takes a named vector of inputs (typically file paths). Use
[`is_target()`](https://stemangiola.github.io/tidytargets/reference/is_target.md)
to point a step at an upstream target. With no `computing_resources`,
the pipeline runs sequentially.

[`library`](https://rdrr.io/r/base/library.html)`(`[`tidytargets`](https://stemangiola.github.io/tidytargets/)`)`` `` ``files`` ``<-`` `[`c`](https://rdrr.io/r/base/c.html)`(`` `` sample_a ``=`` ``"a.rds"``,`` `` sample_b ``=`` ``"b.rds"`` ``)`` `[`saveRDS`](https://rdrr.io/r/base/readRDS.html)`(``1``:``3``, ``files``[[``"sample_a"``]``]``)`` `[`saveRDS`](https://rdrr.io/r/base/readRDS.html)`(``4``:``6``, ``files``[[``"sample_b"``]``]``)`` `` ``files`` ``|>`` `` `[`tt_initialise`](https://stemangiola.github.io/tidytargets/reference/tt_initialise.md)`(``store ``=`` ``"_targets"``)`` ``|>`` `` `[`tt_iterate`](https://stemangiola.github.io/tidytargets/reference/tt_iterate.md)`(`` `` target_output ``=`` ``"data"``,`` `` user_function ``=`` ``readRDS`` ``|>`` `[`quote`](https://rdrr.io/r/base/substitute.html)`(``)``,`` `` file ``=`` ``"input_list"`` ``|>`` `[`is_target`](https://stemangiola.github.io/tidytargets/reference/is_target.md)`(``)`` `` ``)`` ``|>`` `` `[`tt_iterate`](https://stemangiola.github.io/tidytargets/reference/tt_iterate.md)`(`` `` target_output ``=`` ``"summaries"``,`` `` user_function ``=`` ``summary`` ``|>`` `[`quote`](https://rdrr.io/r/base/substitute.html)`(``)``,`` `` object ``=`` ``"data"`` ``|>`` `[`is_target`](https://stemangiola.github.io/tidytargets/reference/is_target.md)`(``)`` `` ``)`` ``|>`` `` `[`tt_evaluate`](https://stemangiola.github.io/tidytargets/reference/tt_evaluate.md)`(``)`

    #> + input_list_file dispatched
    #> ✔ input_list_file completed [0ms, 97 B]
    #> + sample_names_file dispatched
    #> ✔ sample_names_file completed [0ms, 64 B]
    #> + input_list dispatched
    #> ✔ input_list completed [1ms, 97 B]
    #> + sample_names dispatched
    #> ✔ sample_names completed [0ms, 64 B]
    #> + data declared [2 branches]
    #> ✔ data completed [0ms, 201 B]
    #> + summaries declared [2 branches]
    #> ✔ summaries completed [1ms, 324 B]
    #> ✔ ended pipeline [106ms, 8 completed, 0 skipped]

    targets::tar_read(summaries, store = "_targets")
    #> $summaries_77df95261040f9e1
    #>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max.
    #>     1.0     1.5     2.0     2.0     2.5     3.0
    #>
    #> $summaries_71c6d136bc334ef4
    #>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max.
    #>     4.0     4.5     5.0     5.0     5.5     6.0

[`tt_evaluate()`](https://stemangiola.github.io/tidytargets/reference/tt_evaluate.md)
also returns the
[`targets::tar_meta()`](https://docs.ropensci.org/targets/reference/tar_meta.html)
table.
[`tt_initialise()`](https://stemangiola.github.io/tidytargets/reference/tt_initialise.md)
registers two mapped targets for you:

- `input_list` — the named input vector
- `sample_names` — the names of that vector

## Grammar

| Function | Role |
|----|----|
| [`tt_initialise()`](https://stemangiola.github.io/tidytargets/reference/tt_initialise.md) | Start a pipeline: store, optional controller |
| [`tt_iterate()`](https://stemangiola.github.io/tidytargets/reference/tt_iterate.md) | Map a function over inputs |
| [`tt_single()`](https://stemangiola.github.io/tidytargets/reference/tt_single.md) | Add one non-iterated target |
| [`tt_merge()`](https://stemangiola.github.io/tidytargets/reference/tt_merge.md) | Combine iterated results into one object |
| [`tt_report()`](https://stemangiola.github.io/tidytargets/reference/tt_report.md) | Render a Quarto / R Markdown report |
| [`tt_evaluate()`](https://stemangiola.github.io/tidytargets/reference/tt_evaluate.md) | Write the target list and run `tar_make()` |
| [`tt_metadata()`](https://stemangiola.github.io/tidytargets/reference/tt_metadata.md) | Get or set free-form metadata on the pipeline object |
| [`is_target()`](https://stemangiola.github.io/tidytargets/reference/is_target.md) | Mark an argument as an upstream target name |

## Carrying extra information

A `tidytargets` object is a named list: `$initialisation` holds the
arguments given to
[`tt_initialise()`](https://stemangiola.github.io/tidytargets/reference/tt_initialise.md),
and every other element is a target you added. Alongside those sits a
free-form metadata store, reachable only through
[`tt_metadata()`](https://stemangiola.github.io/tidytargets/reference/tt_metadata.md),
for information that is not part of the graph — an API endpoint, a
dataset identifier, a provenance note.

`pipeline`` ``<-`` ``files`` ``|>`` `` `[`tt_initialise`](https://stemangiola.github.io/tidytargets/reference/tt_initialise.md)`(``store ``=`` ``"_targets"``)`` ``|>`` `` `[`tt_metadata`](https://stemangiola.github.io/tidytargets/reference/tt_metadata.md)`(``api_url ``=`` ``"https://api.example.org"``, api_version ``=`` ``2``)`` `` `[`tt_metadata`](https://stemangiola.github.io/tidytargets/reference/tt_metadata.md)`(``pipeline``)``$``api_url`` ``#> [1] "https://api.example.org"`

Metadata is merged on each call, and passing `NULL` removes an entry. It
travels with the object through every grammar step but is not written to
the targets script, so workers cannot see it; values a target needs must
be passed as arguments to
[`tt_iterate()`](https://stemangiola.github.io/tidytargets/reference/tt_iterate.md)
or
[`tt_single()`](https://stemangiola.github.io/tidytargets/reference/tt_single.md).
The store is inert with respect to the rest of the grammar and
constrains nothing — it imposes no restriction on your `target_output`
names.

## Deployment

Pass any controller that `targets::tar_option_set(controller = )`
accepts. tidytargets does not import a backend.

### Local parallel computing

`computing_resources`` ``<-`` ``crew``::`[`crew_controller_local`](https://wlandau.github.io/crew/reference/crew_controller_local.html)`(``workers ``=`` ``10``)`

Pass this to `tt_initialise(computing_resources = ...)`.

### SLURM

`computing_resources`` ``<-`` ``crew.cluster``::`[`crew_controller_slurm`](https://wlandau.github.io/crew.cluster/reference/crew_controller_slurm.html)`(`` `` workers ``=`` ``50``,`` `` tasks_max ``=`` ``1``,`` `` seconds_idle ``=`` ``30``,`` `` options_cluster ``=`` ``crew.cluster``::`[`crew_options_slurm`](https://wlandau.github.io/crew.cluster/reference/crew_options_slurm.html)`(`` `` partition ``=`` ``"standard"`` `` ``)`` ``)`
