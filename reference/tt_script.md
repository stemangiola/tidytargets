# Write the Targets Script Without Running the Pipeline

`{store}.R` is generated from the pipeline object when the pipeline
runs. Call this to write it early, so the `{targets}` functions that
read a script can inspect the graph before anything executes, for
example
[`targets::tar_manifest()`](https://docs.ropensci.org/targets/reference/tar_manifest.html),
[`targets::tar_visnetwork()`](https://docs.ropensci.org/targets/reference/tar_visnetwork.html),
[`targets::tar_outdated()`](https://docs.ropensci.org/targets/reference/tar_outdated.html).

The pipeline's script and store are registered with
[`targets::tar_config_set()`](https://docs.ropensci.org/targets/reference/tar_config_set.html),
so those functions then need no arguments. That writes `_targets.yaml`
in the working directory, which is how `{targets}` is told to use a
script other than `_targets.R`.

Nothing is executed; use
[`tt_evaluate()`](https://stemangiola.github.io/tidytargets/reference/tt_evaluate.md)
to run the pipeline.

## Usage

``` r
tt_script(pipe)
```

## Arguments

- pipe:

  A `tidytargets` object from
  [`tt_initialise()`](https://stemangiola.github.io/tidytargets/reference/tt_initialise.md).

## Value

The script path, invisibly.

## Examples

``` r
if (FALSE) { # \dontrun{
pipe <- tt_initialise(store = "store") |> tt_single(n <- 1)
tt_script(pipe)
targets::tar_manifest()
targets::tar_visnetwork()
} # }
```
