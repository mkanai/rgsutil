#' Check if a Google Cloud Storage file is newer than local cache
#'
#' Compares the modification time of a file in Google Cloud Storage with
#' a local cached version to determine if the remote file has been updated.
#'
#' @param remote_path Character string. The Google Cloud Storage path to check,
#'   must start with "gs://".
#' @param local_path Character string. The path to the local cached file to
#'   compare against.
#'
#' @return Logical. TRUE if the remote file is newer than the local file,
#'   FALSE otherwise.
#'
#' @details
#' This function retrieves the modification timestamp from Google Cloud Storage
#' using \code{gcloud storage ls -l} and compares it with the local file's
#' creation time. This is primarily used by \code{\link{read_gsfile}} to
#' determine whether to use a cached version or download a fresh copy.
#'
#' @note
#' The function will stop with an error if the remote file does not exist.
#' The local file must exist for a meaningful comparison.
#'
#' @examples
#' \dontrun{
#' # Check if remote file has been updated
#' if (check_update("gs://my-bucket/data/file.csv", "/tmp/my-bucket/data/file.csv")) {
#'   message("Remote file is newer, should download")
#' } else {
#'   message("Local cache is up to date")
#' }
#' }
#'
#' @seealso \code{\link{read_gsfile}}
#'
#' @export
#'
check_update <- function(remote_path, local_path) {
  remote_dt <- as.POSIXct(
    system(
      sprintf("gcloud storage ls -l %s | awk 'NR == 1{print $2}'", remote_path),
      intern = TRUE
    ),
    format = "%Y-%m-%dT%H:%M",
    tz = "UTC"
  )
  if (is.null(remote_dt)) {
    stop(paste("Remote file not found:", remote_path))
  }
  local_dt <- file.info(local_path)$ctime
  return(remote_dt > local_dt)
}
