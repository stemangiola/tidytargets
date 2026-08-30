#' Append a factory call to the targets script
#'
#' Writes `target_list <- target_list |> target_append(<fx>(...))` to
#' `{store}.R`. If `target_output` is among `...`, any existing line for
#' that target is removed first so redefining a step does not stack.
#'
#' @param fx Quoted factory, typically `quote(tt_factory)`.
#' @param script Path to the `{targets}` script.
#' @param ... Factory arguments (`command`, `target_output`, ...).
#' @importFrom readr write_lines
#' @importFrom targets tar_config_get
#' @noRd
tar_append = function(fx, script = targets::tar_config_get("script"), ...){
  
  # Deal with additional argument
  additional_args <- 
    list(...) |> 
    
    # I need this because otherwise the quotation of for example the function names 
    # and the target names will be lost, so those object will be evaluated and 
    # triggered because they do not exist in the environment
    quote_name_classes()

  if (!is.null(additional_args$target_output)) {
    delete_lines_with_word(additional_args$target_output, script)
  }
  
  arguments_to_pass  = c(fx)
  
  if (length(additional_args) > 0)
    arguments_to_pass = arguments_to_pass |> c(additional_args)
  
  # Construct the call with substitute
  call_expr =
    as.call(arguments_to_pass) |>
    deparse(width.cutoff = 500)
  
  # Add prefix. Assign so {targets} `eval(parse(script))` sees the grown list
  # in the script environment (target_append is a pure function).
  "target_list <- target_list |> target_append(" |> 
    c(call_expr ) |> 
    c(")") |> 
    
    paste(collapse = " ") |> 
    
    # Write
    write_lines(script, append = TRUE)
  
}

#' Quote elements with class 'name'
#'
#' This function takes a list and returns a new list where any elements
#' with the class 'name' are converted to their quoted equivalent using `quote()`.
#' This is useful for preserving unevaluated expressions in the list.
#'
#' @param lst A list of elements to process.
#' @return A list where elements with class 'name' are quoted.
#' @noRd
quote_name_classes <- function(lst) {
  lapply(lst, function(x) {
    if ("name" %in% class(x)) {
      # Manually create the quoted expression
      as.call(list(as.name("quote"), x))
    } else {
      x  # Leave as is for other elements
    }
  })
}

#' Wrap a language object so it deparses as quote(...)
#'
#' @noRd
wrap_quote <- function(expr) {
  if (is.null(expr) || !is.language(expr)) return(expr)
  as.call(list(as.name("quote"), expr))
}

#' Delete Lines Containing a Word from a File
#'
#' @description
#' Reads a text file and removes all lines that contain a
#' `target_output = "word"` pattern, then writes the result back to disk.
#'
#' @param word The target-output name whose line should be removed.
#' @param file_path Path to the file to modify.
#' @return Invisibly returns NULL; called for its side effect of modifying the file.
#'
#' @importFrom glue glue
#' @export
delete_lines_with_word <- function(word, file_path) {
  # Step 1: Read the file into R as a vector of lines
  lines <- readLines(file_path)
  
  # Step 2: Filter out lines that contain the specified word
  word = glue("target_output = \"{word}\"")
  filtered_lines <- lines[!grepl(word, lines)]
  
  # Step 3: Write the modified content back to the file
  writeLines(filtered_lines, file_path)
}

#' Append Targets to the Pipeline Target List
#'
#' @description
#' Combines an existing list of `tar_target` objects with one or more new
#' targets. The generated pipeline script assigns the result back to
#' `target_list`.
#'
#' @param target_list The existing list of `tar_target` objects to append to.
#' @param ... One or more `tar_target` objects to append.
#' @return The combined list of targets.
#' @export
target_append <- function(target_list, ...) {
  c(target_list, list(...))
}

#' Append Code to a Targets Script
#'
#' @description
#' Appends given code to a 'targets' package script.
#'
#' @param code Code to append.
#' @param script Path to the script file.
#'
#' @importFrom readr write_lines
#' @importFrom targets tar_config_get
#' @noRd
tar_script_append = function(code, script = targets::tar_config_get("script")){
  substitute(code) |>
    deparse() |>
    head(-1) |>
    tail(-1) |>
    write_lines(script, append = TRUE)
}

#' Append Code to a Targets Script
#'
#' @description
#' Appends given code to a 'targets' package script.
#'
#' @param code Code to append.
#' @param script Path to the script file.
#' @param append Logical; append to the existing script if `TRUE`.
#'
#' @importFrom readr write_lines
#' @importFrom targets tar_config_get
#' @noRd
tar_script_append2 = function(code, script = targets::tar_config_get("script"), append = TRUE){
  code |>
    deparse() |>
    head(-1) |>
    tail(-1) |>
    write_lines(script, append = append)
}

#' Append source("path") to the target script
#'
#' Workers need functions that live in a user script, not in the pipeline
#' object. This writes `source(<path>)` into `{store}.R` so that file is
#' loaded before later targets run. `NULL` is a no-op (nothing to source).
#'
#' @param user_function_source_path Character path to an R script, or `NULL`.
#' @param target_script Path to the `{targets}` script (`{store}.R`).
#' @noRd
write_source = function(user_function_source_path, target_script){
  if(user_function_source_path |> is.null() |> not())
    
    source(s) |> 
    substitute(env = list(s =user_function_source_path )) |> 
    deparse() |> 
    write_lines(target_script, append = TRUE)
}
