#' Upload a file to Google Cloud Storage
#'
#' Uploads a local file to Google Cloud Storage using the gcloud storage cp command.
#'
#' @param local_path Character string. The path to the local file to upload.
#' @param remote_path Character string. The destination Google Cloud Storage path,
#'   must start with "gs://".
#'
#' @return NULL (invisibly). The function is called for its side effect of
#'   uploading a file.
#'
#' @details
#' This function uses the \code{gcloud storage cp} command to upload files.
#' Progress messages are displayed during the upload. The function will
#' overwrite existing files at the destination without warning.
#'
#' @note
#' Requires the Google Cloud SDK to be installed and authenticated with
#' appropriate permissions to write to the specified bucket.
#'
#' @examples
#' \dontrun{
#' # Upload a single file
#' upload_gsfile("/local/data/results.csv", "gs://my-bucket/data/results.csv")
#'
#' # Upload with a different name
#' upload_gsfile(
#'   "/local/data/results_2024.csv",
#'   "gs://my-bucket/archive/2024/results.csv"
#' )
#' }
#'
#' @seealso \code{\link{download_gsfile}}, \code{\link{write_gsfile}}
#'
#' @export
#'
upload_gsfile <- function(local_path, remote_path) {
  validate_gs_path(remote_path)
  gcloud_cmd <- get_gcloud_cmd()

  cmd <- sprintf("%s storage cp %s %s", gcloud_cmd, local_path, remote_path)
  message(sprintf("Uploading to %s...", remote_path))
  message(cmd)
  ret <- system(cmd)
  if (ret != 0) {
    stop("Upload failed.")
  }
  message("Uploaded.")
}
