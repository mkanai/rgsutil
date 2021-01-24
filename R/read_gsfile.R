#' Read a remote file on Google Storage
#'
#' @param remote_path a remote path on Google Storage
#' @param extra_pipe_cmd if specified, this will be passed to pipe
#' @param cache.dir a directory for cache
#' @param ... extra parameters for data.table::fread
#'
#' @return a data.frame
#' @export
#'
read_gsfile = function(remote_path, extra_pipe_cmd = NULL, cache.dir = '/tmp', ...) {
  stopifnot(startsWith(remote_path, "gs://"))

  local_path = file.path(cache.dir, substr(remote_path, 6, stop=.Machine$integer.max))
  if (file.exists(local_path) & !check_update(remote_path, local_path)) {
    message(sprintf("Using a cache at %s...", local_path))
    fread_wrapper(local_path, extra_pipe_cmd = extra_pipe_cmd, ...)
  } else {
    download_gsfile(remote_path, dirname(local_path))
    fread_wrapper(local_path, extra_pipe_cmd = extra_pipe_cmd, ...)
  }
}
