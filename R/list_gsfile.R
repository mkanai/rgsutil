#' List files on a remote path
#'
#' @param remote_path a remote path on Google Storage
#'
#' @return a list of files
#' @export
#'
list_gsfile = function(remote_path) {
  suppressWarnings({
    files = system(
      paste("gsutil ls", remote_path),
      intern = TRUE,
      ignore.stderr = TRUE
    )
  })
  return(files)
}
