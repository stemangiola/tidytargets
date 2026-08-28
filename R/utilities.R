# Helper function to add class to an object
add_class <- function(obj, class_name) {
  class(obj) <- c(class_name, class(obj))
  return(obj)
}

stop_if_not_tidytargets <- function() {
  stop(
    "tidytargets says: this step expects a tidytargets object from tt_initialise().",
    call. = FALSE
  )
}

# Negation
not = function(is){	!is }

#' Infer the package that defines a controller-like object
#'
#' Used so the generated pipeline can `library()` the backend that produced
#' `computing_resources` without tidytargets depending on that backend.
#'
#' @param x A controller, controller group, or a plain list of those objects.
#' @return A character vector of package names (possibly empty).
#' @noRd
package_of_object <- function(x) {
  if (is.null(x)) return(character())

  # Recurse into a plain list of controllers, but not S3/S4/R6 objects
  if (is.list(x) && !is.object(x)) {
    return(unique(unlist(lapply(x, package_of_object), use.names = FALSE)))
  }

  pkgs <- character()

  pkg_attr <- attr(class(x), "package")
  if (!is.null(pkg_attr) && !pkg_attr %in% c(".GlobalEnv", "base")) {
    pkgs <- c(pkgs, pkg_attr)
  }

  if (is.function(x$initialize)) {
    pkg <- utils::packageName(environment(x$initialize))
    if (!is.null(pkg)) pkgs <- c(pkgs, pkg)
  }

  unique(pkgs)
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

tar_append = function(fx, tiers = NULL, script = targets::tar_config_get("script"), ...){
  
  # Deal with additional argument
  additional_args <- 
    list(...) |> 
    
    # I need this because otherwise the quotation of for example the function names 
    # and the target names will be lost, so those object will be evaluated and 
    # triggered because they do not exist in the environment
    quote_name_classes()
  
  arguments_to_pass  = c(fx)
  
  if(tiers |> is.null() |> not())
    arguments_to_pass = arguments_to_pass |> c(list(tiers = tiers))
  
  if (length(additional_args) > 0)
    arguments_to_pass = arguments_to_pass |> c(additional_args)
  
  # Construct the call with substitute
  call_expr = 
    as.call(arguments_to_pass) |> 
    deparse()
  
  # Add prefix
  "target_list |> target_append(" |> 
    c(call_expr ) |> 
    c(")") |> 
    
    paste(collapse = " ") |> 
    
    # Write
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

#' Get positions of each unique element in a vector
#'
#' This function takes a vector and returns a named list where each unique
#' element of the input vector maps to the positions at which it occurs.
#'
#' @param input_vector A vector of elements.
#' @return A named list where each name is a unique element from the input vector
#' and each value is a vector of positions where that element occurs.
#' @examples
#' input_vector <- c("a", "a", "b", "c", "a")
#' positions_list <- get_positions(input_vector)
#' print(positions_list)
#' @importFrom dplyr tibble
#' @importFrom dplyr group_by
#' @importFrom dplyr summarise
#' @importFrom purrr set_names
#' @export
get_positions <- function(input_vector) {
  # Create a tibble with the input vector and their positions
  df <- tibble(value = input_vector, position = seq_along(input_vector))
  
  # Group by value and summarise the positions
  result <- df %>%
    group_by(value) %>%
    summarise(positions = list(position), .groups = 'drop')
  
  # Convert the result to a named list
  result_list <- set_names(result$positions, result$value)
  
  return(result_list)
}

#' Add Tier Inputs to a Function Call String
#'
#' This function modifies a function call string by appending a tier label to specified arguments.
#'
#' @param command A character string representing a function call, e.g., "a(b, c, d)".
#' @param arguments_to_tier A character vector specifying which arguments should be tiered, e.g., c("b", "c", "d").
#' @param i A character string representing the tier label to be appended, e.g., "_1".
#'
#' @return A character string representing the modified function call with tiered arguments.
#'
#' @importFrom stringr str_replace
#' @importFrom glue glue
#' @importFrom purrr set_names
#'
#' @noRd
add_tier_inputs <- function(command, arguments_to_tier, i) {
  
  if(i |> length() > 1) stop("tidytargets says: argument i must be of length one")
  
  if(length(arguments_to_tier)==0) return(command)
  
  command = command |> deparse() |> paste(collapse = "")  
  
  # Create a named vector for replacements
  replacement_regexp <- glue("{arguments_to_tier}_{i}") |> as.character() |> set_names(arguments_to_tier)
  
  # Function to add word boundaries and perform the replacements
  # This because we only replace WHOLE words
  add_word_boundaries_and_replace <- function(command, replacements) {
    for (pattern in names(replacements)) {
      # Create the regex pattern with word boundaries
      pattern_with_boundaries <- paste0("\\b", pattern, "\\b")
      # Perform the replacement for each pattern
      command <- str_replace(command, pattern_with_boundaries, replacements[pattern])
    }
    return(command)
  }
  
  # Replace the specified arguments in the command with their tiered versions
  command |> add_word_boundaries_and_replace(replacement_regexp) |>  rlang::parse_expr()
  
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

#' Names of pipeline targets referenced in a command expression
#'
#' @param command A language object (or something that is not, in which case
#'   nothing is returned).
#' @param tt_input A `tidytargets` object.
#' @param value Character vector of `iterate` modes to match.
#' @return A character vector of target names.
#' @noRd
command_targets <- function(command, tt_input, value) {
  if (!is.language(command)) return(character())

  vars <- all.vars(command)
  vars <- vars[vars %in% names(tt_input)]

  Filter(
    function(v) isTRUE(tt_input[[v]]$iterate %in% value),
    vars
  )
}

#' Replace a symbol throughout an expression
#'
#' @noRd
replace_symbol <- function(expr, from, to) {
  from_sym <- as.name(from)
  if (is.name(expr)) {
    if (identical(expr, from_sym)) return(to)
    return(expr)
  }
  if (is.call(expr)) {
    return(as.call(lapply(expr, replace_symbol, from = from, to = to)))
  }
  expr
}

#' Expand tiered target names in a command to `c(name_tier, ...)`
#'
#' @noRd
expand_tiered_command <- function(command, target_names, tiers) {
  if (length(target_names) == 0) return(command)

  for (nm in target_names) {
    replacement <- as.call(
      c(as.name("c"), lapply(as.list(tiers), function(tier) as.name(paste0(nm, "_", tier))))
    )
    command <- replace_symbol(command, nm, replacement)
  }
  command
}

build_pattern = function(arguments_to_tier = c(), other_arguments_to_map = c(), index = c()){
  
  pattern = NULL 
  
  if(
    arguments_to_tier |> length() > 0 |
    other_arguments_to_map |> length() > 0
  ){
    
    pattern = as.name("map")
    
    if(arguments_to_tier |> length() > 0)
      pattern = pattern |> c(
        arguments_to_tier |>
          map(
            ~ substitute(
              slice(input, index  = arg ), 
              list(input = as.symbol(.x), arg=index)
            ) 
          )
      )
    
    if(other_arguments_to_map |> length() > 0){
      
      pattern = pattern |> c(other_arguments_to_map |> lapply(as.name))
      
    }
    
    pattern = as.call(pattern)
    
  }
  
  pattern
  
}

write_source = function(user_function_source_path, target_script){
  if(user_function_source_path |> is.null() |> not())
    
    source(s) |> 
    substitute(env = list(s =user_function_source_path )) |> 
    deparse() |> 
    write_lines(target_script, append = TRUE)
}

#' Append Targets to the Pipeline Target List
#'
#' @description
#' Appends one or more `tar_target` objects to the global `target_list` used
#' by the tidytargets pipeline script. This function modifies `target_list` in the
#' calling environment via `<<-`.
#'
#' @param target_list The existing list of `tar_target` objects to append to.
#' @param ... One or more `tar_target` objects to append.
#' @return Invisibly returns `NULL`; called for its side effect of updating
#'   `target_list` in the enclosing environment.
#' @export
target_append <- function(target_list, ...) {
  # Append the new elements to the list
  target_list <<- c(target_list, list(...))
  
}
