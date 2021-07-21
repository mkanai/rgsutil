#' Check whether a remote file is updated
#'
#' @param remote_path a remote path on Google Storage
#' @param local_path a local path to check whether updated
#'
#' @return whether the file is updated
#' @export
#'
check_update = function(remote_path, local_path) {
  remote_dt = as.POSIXct(system(
    sprintf("gsutil ls -l %s | awk 'NR == 1{print $2}'", remote_path),
    intern = TRUE
  ),
  format = "%Y-%m-%dT%H:%M",
  tz = 'UTC')
  if (is.null(remote_dt)) {
    stop(paste("Remote file not found:", remote_path))
  }
  local_dt = file.info(local_path)$ctime
  return(remote_dt > local_dt)
}
