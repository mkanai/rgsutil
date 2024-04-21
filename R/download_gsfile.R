#' Download a remote file on Google Storage
#'
#' @param remote_path a remote path on Google Storage
#' @param dest_dir a destination directory to download
#'
#' @export
#'
download_gsfile = function(remote_path, dest_dir) {
  if (!dir.exists(dest_dir)) {
    dir.create(dest_dir, recursive = TRUE)
  }
  cmd = sprintf("gcloud storage cp %s %s/", remote_path, dest_dir)
  message(sprintf("Downloading %s...", remote_path))
  message(cmd)
  system(cmd)
  message("Downloaded.")
}
