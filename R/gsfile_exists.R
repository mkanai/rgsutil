#' Check whether a remote file exists
#'
#' @param remote_path a remote path on Google Storage
#'
#' @return whether the file exists
#' @export
#'
gsfile_exists = function(remote_path) {
  files = list_gsfile(remote_path)
  return(length(files) > 0)
}
