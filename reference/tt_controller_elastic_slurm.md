# Build an elastic SLURM crew controller group

Wraps a common `{crew.cluster}` HPC pattern: several
[`crew.cluster::crew_controller_slurm()`](https://wlandau.github.io/crew.cluster/reference/crew_controller_slurm.html)
resource tiers, sized from small to large, each one falling back to the
next tier up (via its `backup` argument) once its workers exhaust
`crashes_max`. Returns a
[`crew::crew_controller_group()`](https://wlandau.github.io/crew/reference/crew_controller_group.html),
ready to pass to `tt_initialise(computing_resources = )`. tidytargets
does not depend on `{crew}`/`{crew.cluster}`; install them yourself to
use this wrapper.

## Usage

``` r
tt_controller_elastic_slurm(
  workers,
  mem_gb_per_job,
  time_hours = 24,
  crashes_max = 2,
  cpus_per_task = 1,
  seconds_idle = 30,
  ...
)
```

## Arguments

- workers:

  Numeric vector (or single value, recycled to the number of tiers),
  number of workers for each tier. Required.

- mem_gb_per_job:

  Numeric vector, memory in gigabytes required per worker for each tier,
  ordered from smallest to largest. Tier names are generated
  automatically from these values (e.g. `5` becomes `"elastic_5"`).

- time_hours:

  Numeric vector (or single value, recycled to the number of tiers), the
  SLURM walltime allocated to each worker, in hours. This is the
  *lifetime of the worker*, not the run time of one target: a worker is
  a SLURM job that stays alive to run multiple targets back to back, and
  `{targets}` dispatches a fresh target to it each time it goes idle.
  When `time_hours` elapses, SLURM kills the worker (and whatever target
  it is running at that moment); `{crew}` then relaunches that target on
  a brand new worker. Set it as long as practical so a worker survives
  as many targets as possible, and always longer than the longest single
  target it may run — a value shorter than one target's execution time
  guarantees that target is killed before it can finish. Default: `24`.

- crashes_max:

  Numeric vector (or single value, recycled to the number of tiers),
  crashes allowed on a tier before falling back to the next one up.
  Default: `2`.

- cpus_per_task:

  Numeric vector (or single value, recycled to the number of tiers),
  CPUs per task for each tier. Default: `1`.

- seconds_idle:

  Numeric seconds each worker idles before shutting down, passed to
  every `crew_controller_slurm()`. Default: `30`.

- ...:

  Additional arguments passed to every
  [`crew.cluster::crew_options_slurm()`](https://wlandau.github.io/crew.cluster/reference/crew_options_slurm.html)
  call (e.g. `partition`).

## Value

A `crew_class_controller_group` object from
[`crew::crew_controller_group()`](https://wlandau.github.io/crew/reference/crew_controller_group.html).

## Examples

``` r
if (FALSE) { # \dontrun{
# workers and mem_gb_per_job are required; every other argument may be a
# single value (recycled to every tier) or one value per tier.
computing_resources <- tt_controller_elastic_slurm(
  workers = c(64, 48, 32, 24, 16, 8),
  mem_gb_per_job = c(5, 10, 20, 40, 80, 160),
  time_hours = c(4, 4, 4, 4, 4, 24),
  crashes_max = c(6, 1, 1, 1, 1, 2)
)
tt_initialise(computing_resources = computing_resources)
} # }
```
