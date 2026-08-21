#' tidytargets: Tidy Grammar for Targets Pipelines
#'
#' @importFrom methods is
#' @importFrom stats setNames
#' @importFrom utils head tail
#' @importFrom glue glue
#' @importFrom stringr str_detect str_subset str_replace
#' @importFrom purrr map map2 set_names
#' @importFrom readr write_lines
#' @importFrom magrittr %>%
#' @importFrom dplyr tibble group_by summarise
#' @importFrom rlang parse_expr
#' @importFrom targets tar_target_raw tar_resources tar_resources_crew tar_option_get tar_make tar_meta tar_config_get tar_option_set tar_cue
#' @importFrom tarchetypes tar_quarto_raw
#' @importFrom here here
#' @importFrom callr r
"_PACKAGE"

utils::globalVariables(c("target_list", "value", "position", "user_function"))
