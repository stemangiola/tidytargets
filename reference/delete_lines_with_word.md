# Delete Lines Containing a Word from a File

Reads a text file and removes all lines that contain a
`target_output = "word"` pattern, then writes the result back to disk.

## Usage

``` r
delete_lines_with_word(word, file_path)
```

## Arguments

- word:

  The target-output name whose line should be removed.

- file_path:

  Path to the file to modify.

## Value

Invisibly returns NULL; called for its side effect of modifying the
file.
