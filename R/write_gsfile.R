#' Write a data frame to Google Cloud Storage
#'
#' Writes a data frame to Google Cloud Storage by first writing to a temporary
#' local file and then uploading it. Supports overwrite protection and various
#' file formats.
#'
#' @param x A data.frame or data.table to write.
#' @param remote_path Character string. The destination Google Cloud Storage path
#'   starting with "gs://".
#' @param sep Character string. Field separator for the output file.
#'   Defaults to "\\t" (tab).
#' @param overwrite Logical. Whether to overwrite an existing remote file.
#'   Defaults to FALSE for safety.
#' @param cache.dir Character string. Directory for temporary local files.
#'   Defaults to getOption("rgsutil.cache_dir") or a temp directory.
#' @param ... Additional arguments passed to \code{\link[data.table]{fwrite}}.
#'
#' @return NULL (invisibly). The function is called for its side effect of
#'   uploading a file to Google Cloud Storage.
#'
#' @details
#' The function performs the following steps:
#' \enumerate{
#'   \item Checks if the remote file exists (unless overwrite = TRUE)
#'   \item Writes the data to a temporary local file
#'   \item Uploads the file to Google Cloud Storage
#'   \item Removes the temporary local file
#' }
#'
#' @examples
#' \dontrun{
#' # Write a data frame to Google Cloud Storage
#' df <- data.frame(x = 1:10, y = letters[1:10])
#' write_gsfile(df, "gs://my-bucket/data/output.tsv")
#'
#' # Write as CSV with overwrite
#' write_gsfile(df, "gs://my-bucket/data/output.csv",
#'   sep = ",", overwrite = TRUE
#' )
#'
#' # Write with compression
#' write_gsfile(df, "gs://my-bucket/data/output.tsv.gz",
#'   compress = "gzip"
#' )
#' }
#'
#' @seealso \code{\link{read_gsfile}}, \code{\link{upload_gsfile}},
#'   \code{\link{gsfile_exists}}
#'
#' @export
write_gsfile <- function(x, remote_path, sep = "\t", overwrite = FALSE, cache.dir = NULL, ...) {
  validate_gs_path(remote_path)

  # Use configured cache directory if not specified
  if (is.null(cache.dir)) {
    cache.dir <- get_cache_dir()
  }

  local_path <- file.path(cache.dir, substr(remote_path, 6, stop = .Machine$integer.max))
  if (gsfile_exists(remote_path)) {
    if (!overwrite) {
      stop(sprintf("Remote file exists: %s", remote_path))
    }
    message("This overwrites a remote file")
  }
  fwrite_wrapper(x, local_path, sep = sep, ...)
  upload_gsfile(local_path, remote_path)
  file.remove(local_path)
  return()
}
