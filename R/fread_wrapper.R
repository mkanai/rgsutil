#' Wrap data.table::fread for bgz or pipe
#'
#' @param path a path to file
#' @param extra_pipe_cmd if specified, this will be added to pipe
#' @param ... extra parameters for data.table::fread
#'
#' @importFrom  data.table fread
#' @return a data.frame
#'
fread_wrapper = function(path, extra_pipe_cmd = NULL, ...) {
  is_bgz = tools::file_ext(path) == "bgz"
  if (!is_bgz & is.null(extra_pipe_cmd)) {
    return(data.table::fread(path, data.table = F))
  }
  cmd = sprintf("%s %s", ifelse(is_bgz, "gunzip -cd", "cat"), path)
  if (!is.null(extra_pipe_cmd)) {
    cmd = paste(cmd, extra_pipe_cmd, sep = " | ")
  }
  return(data.table::fread(cmd = cmd, data.table = FALSE, ...))
}
