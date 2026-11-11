# tidytargets (alpha)

A tidy, pipe-friendly grammar for `{targets}`, internally based on [targets factories](https://books.ropensci.org/targets/static.html#target-factories).

Compose pipelines with pipes (`|>`) and run them locally, on HPC, or in the cloud. `tt_initialise()` constructs a `tidytargets` object; `tt_iterate()`, `tt_single()`, `tt_split()`, `tt_merge()`, `tt_report()`, and `tt_evaluate()` are methods on that class. Those calls are factories that write a `{targets}` dependency graph. Compute backends (for example `{crew}` or `{crew.cluster}`) are optional and passed in at `tt_initialise()`.

The grammar is **lazy** and **incremental**. Piping steps only appends factories to the targets script; nothing is computed until `tt_evaluate()` (or evaluating the object; e.g., printing it in the console). 

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

### Submitting jobs to a remote HPC from your local machine


The controller stays in the R session on your machine. A `command_submit`
wrapper copies each job script to Gadi and runs `qsub` there. The worker dials
back through an SSH tunnel: a compute node has no route to your machine, and
Gadi only lets that tunnel listen on the login node's `127.0.0.1`, so `nc` on
the login node accepts the compute node and forwards it into the tunnel. The
job runs `nc` again, so the worker keeps dialling `127.0.0.1`, which is the
address in the certificate `{crew}` creates. One SSH master
connection carries the tunnel, the relay, and `qsub`, so all three land on the
same login node.

`storage` and `retrieval` have to be `"main"`. The default `"worker"` fails:
the compute node tries to read and write the store, and the store is on your
machine. `"main"` sends every input to the worker and every result back, so
each object passes through the R session on your machine. tidytargets drops an
object once it has been saved, but the session holds whatever is in flight. One
large object costs about its size in memory, and several workers finishing
together cost that several times over.

Save this file, then run the terminal commands, then run the R code.

**File `remote_qsub.sh`.** Save it on your machine, in the directory where you start R, and run `chmod +x remote_qsub.sh`. `{crew}` calls this file instead of `qsub`. It rewrites the script Gadi rejects, copies it to `gadi.nci.org.au`, and submits it. `sed -i ''` is the macOS form.

``` bash
#!/bin/bash
# remote_qsub.sh
set -euo pipefail
script=$1
remote=YOUR_USER@gadi.nci.org.au
dir=/scratch/YOUR_PROJECT/$USER/crew_scripts
sed -i '' \
  -e '/^#PBS -J 1-1$/d' \
  -e 's/^#PBS -l ppn=/#PBS -l ncpus=/' \
  -e 's/^#PBS -l mem=\([0-9.]*\)gb$/#PBS -l mem=\1GB/' \
  "$script"
ssh -S /tmp/gadi.sock "$remote" "mkdir -p $dir && cat > $dir/$(basename "$script")" < "$script"
ssh -S /tmp/gadi.sock "$remote" "/opt/pbs/default/bin/qsub $dir/$(basename "$script")"
```

**Run in your terminal.** The first command logs in to `gadi.nci.org.au` and opens the tunnel back to your machine. The second runs `nc` on that login node and keeps running: it listens on the login node's own address and forwards each connection into the tunnel. Leave it running until the pipeline finishes. Bash cannot listen on a port. `nc` on Gadi is ncat, and `-k` keeps it accepting connections. `hostname -I` prints the login node's address; the R code below calls it `LOGIN_NODE_IP`.

``` bash
ssh -o ControlMaster=yes -o ControlPath=/tmp/gadi.sock -o ControlPersist=2h \
  -fN -R 127.0.0.1:47200:127.0.0.1:47200 YOUR_USER@gadi.nci.org.au
ssh -S /tmp/gadi.sock YOUR_USER@gadi.nci.org.au \
  'nc -k -l $(hostname -I | cut -d" " -f1) 47201 -c "nc 127.0.0.1 47200"'
```

**Run in R.** `host` and `port` are the tunnel on your machine. Everything else here is what Gadi needs to start the worker and send it back through that tunnel. The controller uses `{crew}`'s default of one worker, which is the job `remote_qsub.sh` accepts.

``` r
library(crew.cluster)
library(tidytargets)

computing_resources <- crew_controller_pbs(
  host = "127.0.0.1",
  port = 47200,
  options_cluster = crew_options_pbs(
    command_submit = "./remote_qsub.sh",
    script_lines = c(
      "#PBS -P YOUR_PROJECT",
      "#PBS -q express",
      "#PBS -l storage=scratch/YOUR_PROJECT",
      "source /etc/profile.d/modules.sh",
      "module load intel-compiler-llvm/2025.3.2",
      "module load intel-mkl/2025.0.1",
      "module load R/4.5.0",
      "export R_LIBS_USER=/scratch/YOUR_PROJECT/$USER/Rlib",
      "nc -k -l 127.0.0.1 47200 -c 'nc LOGIN_NODE_IP 47201' &",
      "sleep 2"
    )
  )
)

inputs <- list(sample_a = 1:3, sample_b = 4:6)
inputs |>
  tt_initialise(
    computing_resources = computing_resources,
    packages = "tidytargets",
    storage = "main",
    retrieval = "main"
  ) |>
  tt_iterate(summaries <- summary(input_list)) |>
  tt_evaluate()
```

### Elastic SLURM (auto-scaling tiers)

`tt_controller_elastic_slurm()` wraps several `crew.cluster::crew_controller_slurm()`
resource tiers, sized from small to large, into a `crew::crew_controller_group()`.
A tier automatically falls back to the next tier up once its workers exhaust
`crashes_max` (for example, once a job runs out of memory), so most jobs run
on cheap, small workers while a few fall through to progressively larger ones.
`{crew}` and `{crew.cluster}` are not dependencies of tidytargets; install them
yourself to use this wrapper.

``` r
computing_resources <- tt_controller_elastic_slurm(
  workers = 100,
  mem_gb_per_job = c(5, 10, 20, 50, 100)
)
```

Pass this to `tt_initialise(computing_resources = ...)`.

## Submitting jobs to a remote HPC from your local machine

The controller stays in the R session on your machine. A `command_submit` wrapper copies each job script to Gadi and runs `qsub` there. The worker dials back through an SSH tunnel: a compute node has no route to your machine, and Gadi only lets that tunnel listen on the login node's `127.0.0.1`, so `nc` on the login node accepts the compute node and forwards it into the tunnel. The job runs `nc` again, so the worker keeps dialling `127.0.0.1`, which is the address in the certificate `{crew}` creates. One SSH master connection carries the tunnel, the relay, and `qsub`, so all three land on the same login node.

`storage` and `retrieval` have to be `"main"`. The default `"worker"` fails: the compute node tries to read and write the store, and the store is on your machine. `"main"` sends every input to the worker and every result back, so each object passes through the R session on your machine. tidytargets drops an object once it has been saved, but the session holds whatever is in flight. One large object costs about its size in memory, and several workers finishing together cost that several times over.

Save this file, then run the terminal commands, then run the R code.

**File `remote_qsub.sh`.** Save it on your machine, in the directory where you start R, and run `chmod +x remote_qsub.sh`. `{crew}` calls this file instead of `qsub`. It rewrites the script Gadi rejects, copies it to `gadi.nci.org.au`, and submits it. `sed -i ''` is the macOS form.

```{bash remote-qsub, eval = FALSE}
#!/bin/bash
# remote_qsub.sh
set -euo pipefail
script=$1
remote=YOUR_USER@gadi.nci.org.au
dir=/scratch/YOUR_PROJECT/$USER/crew_scripts
sed -i '' \
  -e '/^#PBS -J 1-1$/d' \
  -e 's/^#PBS -l ppn=/#PBS -l ncpus=/' \
  -e 's/^#PBS -l mem=\([0-9.]*\)gb$/#PBS -l mem=\1GB/' \
  "$script"
ssh -S /tmp/gadi.sock "$remote" "mkdir -p $dir && cat > $dir/$(basename "$script")" < "$script"
ssh -S /tmp/gadi.sock "$remote" "/opt/pbs/default/bin/qsub $dir/$(basename "$script")"
```

**Run in your terminal.** The first command logs in to `gadi.nci.org.au` and opens the tunnel back to your machine. The second runs `nc` on that login node and keeps running: it listens on the login node's own address and forwards each connection into the tunnel. Leave it running until the pipeline finishes. Bash cannot listen on a port. `nc` on Gadi is ncat, and `-k` keeps it accepting connections. `hostname -I` prints the login node's address; the R code below calls it `LOGIN_NODE_IP`.

```{bash gadi-tunnel, eval = FALSE}
ssh -o ControlMaster=yes -o ControlPath=/tmp/gadi.sock -o ControlPersist=2h \
  -fN -R 127.0.0.1:47200:127.0.0.1:47200 YOUR_USER@gadi.nci.org.au
ssh -S /tmp/gadi.sock YOUR_USER@gadi.nci.org.au \
  'nc -k -l $(hostname -I | cut -d" " -f1) 47201 -c "nc 127.0.0.1 47200"'
```

**Run in R.** `host` and `port` are the tunnel on your machine. Everything else here is what Gadi needs to start the worker and send it back through that tunnel. The controller uses `{crew}`'s default of one worker, which is the job `remote_qsub.sh` accepts.

```{r pbs, eval = FALSE}
library(crew.cluster)
library(tidytargets)

computing_resources <- crew_controller_pbs(
  host = "127.0.0.1",
  port = 47200,
  options_cluster = crew_options_pbs(
    command_submit = "./remote_qsub.sh",
    script_lines = c(
      "#PBS -P YOUR_PROJECT",
      "#PBS -q express",
      "#PBS -l storage=scratch/YOUR_PROJECT",
      "source /etc/profile.d/modules.sh",
      "module load intel-compiler-llvm/2025.3.2",
      "module load intel-mkl/2025.0.1",
      "module load R/4.5.0",
      "export R_LIBS_USER=/scratch/YOUR_PROJECT/$USER/Rlib",
      "nc -k -l 127.0.0.1 47200 -c 'nc LOGIN_NODE_IP 47201' &",
      "sleep 2"
    )
  )
)

inputs <- list(sample_a = 1:3, sample_b = 4:6)
inputs |>
  tt_initialise(
    computing_resources = computing_resources,
    packages = "tidytargets",
    storage = "main",
    retrieval = "main"
  ) |>
  tt_iterate(summaries <- summary(input_list)) |>
  tt_evaluate()
```


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
