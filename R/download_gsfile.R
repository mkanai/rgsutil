#' Download a file from Google Cloud Storage
#'
#' Downloads a file from Google Cloud Storage to a local directory using the
#' gcloud storage cp command. Creates the destination directory if it doesn't exist.
#'
#' @param remote_path Character string. The Google Cloud Storage path to download,
#'   must start with "gs://".
#' @param dest_dir Character string. The local destination directory where the
#'   file will be downloaded.
#'
#' @return NULL (invisibly). The function is called for its side effect of
#'   downloading a file.
#'
#' @details
#' This function uses the \code{gcloud storage cp} command to download files.
#' It will create the destination directory recursively if it doesn't exist.
#' Progress messages are displayed during the download.
#'
#' @note
#' Requires the Google Cloud SDK to be installed and authenticated with
#' appropriate permissions to access the specified bucket.
#'
#' @examples
#' \dontrun{
#' # Download a single file
#' download_gsfile("gs://my-bucket/data/file.csv", "/local/data")
#'
#' # Download to a nested directory (will be created if needed)
#' download_gsfile("gs://my-bucket/data/file.csv", "/local/data/2024/january")
#' }
#'
#' @seealso \code{\link{upload_gsfile}}, \code{\link{read_gsfile}}
#'
#' @export
#'
download_gsfile <- function(remote_path, dest_dir) {
  if (!dir.exists(dest_dir)) {
    dir.create(dest_dir, recursive = TRUE)
  }
  cmd <- sprintf("gcloud storage cp %s %s/", remote_path, dest_dir)
  message(sprintf("Downloading %s...", remote_path))
  message(cmd)
  system(cmd)
  message("Downloaded.")
}
