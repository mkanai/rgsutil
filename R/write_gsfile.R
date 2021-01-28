#' Write a remote file on Google Storage
#'
#' @param x a data.frame to write
#' @param remote_path a remote path on Google Storage
#' @param sep an output separator
#' @param overwrite whether to overwrite an existing remote file
#' @param cache.dir a directory for cache
#' @param ... extra parameters for data.table::fread
#'
#' @export
write_gsfile = function(x, remote_path, sep = "\t", overwrite = FALSE, cache.dir = '/tmp', ...) {
  stopifnot(startsWith(remote_path, "gs://"))

  local_path = file.path(cache.dir, substr(remote_path, 6, stop=.Machine$integer.max))
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
