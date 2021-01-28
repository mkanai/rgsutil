#' Upload a local file on Google Storage
#'
#' @param local_path a local path
#' @param remote_path a remote path on Google Storage
#'
#' @export
#'
upload_gsfile = function(local_path, remote_path) {
  cmd = sprintf("gsutil cp %s %s", local_path, remote_path)
  message(sprintf("Uploading to %s...", remote_path))
  message(cmd)
  ret = system(cmd)
  if (ret != 0) {
    stop("Upload failed.")
  }
  message("Uploaded.")
}
