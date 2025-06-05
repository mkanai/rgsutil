#' Enhanced file reader with compression and pipe support
#'
#' A wrapper around \code{\link[data.table]{fread}} that automatically handles
#' BGZ-compressed files and supports piping through shell commands before reading.
#'
#' @param path Character string. Path to the file to read.
#' @param extra_pipe_cmd Character string. Optional shell command to pipe the file
#'   through before reading (e.g., "grep pattern", "head -n 1000", "cut -f1,3").
#' @param ... Additional arguments passed to \code{\link[data.table]{fread}}.
#'
#' @return A data.frame containing the file contents.
#'
#' @details
#' This function enhances data.table::fread by:
#' \itemize{
#'   \item Automatically decompressing .bgz files using gunzip
#'   \item Supporting arbitrary shell command pipelines for pre-processing
#'   \item Returning a data.frame (not data.table) by default
#' }
#'
#' The function checks the file extension and applies appropriate handling:
#' \itemize{
#'   \item .bgz files are automatically decompressed with \code{gunzip -cd}
#'   \item If extra_pipe_cmd is provided, it's added to the pipeline
#'   \item Regular files without special handling are read directly
#' }
#'
#' @note
#' This is an internal function primarily used by \code{\link{read_gsfile}},
#' but can be used directly for local files.
#'
#' @examples
#' \dontrun{
#' # Read a regular file
#' df <- fread_wrapper("data.csv")
#'
#' # Read a BGZ compressed file
#' df <- fread_wrapper("data.tsv.bgz", sep = "\t")
#'
#' # Read first 100 lines of a large file
#' df <- fread_wrapper("large_file.csv", extra_pipe_cmd = "head -n 100")
#'
#' # Filter specific columns while reading
#' df <- fread_wrapper("data.tsv", extra_pipe_cmd = "cut -f1,3,5")
#' }
#'
#' @seealso \code{\link{read_gsfile}}, \code{\link[data.table]{fread}}
#'
#' @importFrom data.table fread
fread_wrapper <- function(path, extra_pipe_cmd = NULL, ...) {
  is_bgz <- tools::file_ext(path) == "bgz"
  if (!is_bgz & is.null(extra_pipe_cmd)) {
    return(data.table::fread(path, data.table = F, ...))
  }
  cmd <- sprintf("%s %s", ifelse(is_bgz, "gunzip -cd", "cat"), path)
  if (!is.null(extra_pipe_cmd)) {
    cmd <- paste(cmd, extra_pipe_cmd, sep = " | ")
  }
  return(data.table::fread(cmd = cmd, data.table = FALSE, ...))
}
