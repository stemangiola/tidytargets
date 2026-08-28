#' tidytargets: Tidy Pipe-Friendly Grammar for Targets Pipelines
#'
#' @importFrom methods is
#' @importFrom utils head tail
#' @importFrom glue glue
#' @importFrom purrr set_names
#' @importFrom readr write_lines
#' @importFrom qs2 qs_save qs_read
#' @importFrom targets tar_target_raw tar_option_get tar_make tar_meta tar_config_get tar_option_set tar_cue tar_read_raw tar_exist_objects
#' @importFrom tarchetypes tar_quarto_raw
#' @importFrom callr r
"_PACKAGE"

utils::globalVariables(c("target_list", "command"))
