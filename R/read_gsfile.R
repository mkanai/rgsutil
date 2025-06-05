#' Read a file from Google Cloud Storage
#'
#' Downloads and reads a file from Google Cloud Storage with automatic caching.
#' The function checks for cached versions and only downloads if the remote file
#' has been updated. Supports compressed files (.bgz) and custom pipe commands.
#'
#' @param remote_path Character string. A Google Cloud Storage path starting with "gs://".
#' @param extra_pipe_cmd Character string. Optional shell command to pipe the file through
#'   before reading (e.g., "grep pattern" or "head -n 100").
#' @param cache.dir Character string. Directory for caching downloaded files.
#'   Defaults to "/tmp".
#' @param ... Additional arguments passed to \code{\link[data.table]{fread}}.
#'
#' @return A data.frame containing the file contents.
#'
#' @details
#' The function implements smart caching by:
#' \itemize{
#'   \item Storing files in cache.dir with the same directory structure as the GS path
#'   \item Checking if the remote file has been updated using \code{\link{check_update}}
#'   \item Only downloading when necessary
#' }
#'
#' @examples
#' \dontrun{
#' # Read a CSV file from Google Cloud Storage
#' df <- read_gsfile("gs://my-bucket/data/file.csv")
#'
#' # Read only first 1000 lines of a large file
#' df <- read_gsfile("gs://my-bucket/data/large.csv",
#'   extra_pipe_cmd = "head -n 1000"
#' )
#'
#' # Read a compressed file with custom delimiter
#' df <- read_gsfile("gs://my-bucket/data/file.tsv.bgz", sep = "\t")
#' }
#'
#' @seealso \code{\link{write_gsfile}}, \code{\link{download_gsfile}},
#'   \code{\link{check_update}}
#'
#' @export
#'
read_gsfile <- function(remote_path, extra_pipe_cmd = NULL, cache.dir = "/tmp", ...) {
  stopifnot(startsWith(remote_path, "gs://"))

  local_path <- file.path(cache.dir, substr(remote_path, 6, stop = .Machine$integer.max))
  if (file.exists(local_path) & !check_update(remote_path, local_path)) {
    message(sprintf("Using a cache at %s...", local_path))
    fread_wrapper(local_path, extra_pipe_cmd = extra_pipe_cmd, ...)
  } else {
    download_gsfile(remote_path, dirname(local_path))
    fread_wrapper(local_path, extra_pipe_cmd = extra_pipe_cmd, ...)
  }
}
