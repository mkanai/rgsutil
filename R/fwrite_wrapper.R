#' Wrap data.table::fwrite for bgz or pipe
#'
#' @param x a data.frame to write
#' @param path a path to file
#' @param sep an output separator
#' @param ... extra parameters for data.table::fwrite
#'
#' @importFrom  data.table fwrite
fwrite_wrapper = function(x,
                          path,
                          sep = "\t",
                          na = "NA",
                          ...) {
  dest_dir = dirname(path)
  if (!dir.exists(dest_dir)) {
    dir.create(dest_dir, recursive = TRUE)
  }

  is_bgz = tools::file_ext(path) == "bgz"
  if (!is_bgz) {
    return(data.table::fwrite(
      x,
      path,
      quote = FALSE,
      row.names = FALSE,
      sep = sep,
      na = na,
      ...
    ))
  }

  tmp_path = paste0(path, "-tmp")
  data.table::fwrite(
    x,
    tmp_path,
    quote = FALSE,
    row.names = FALSE,
    sep = sep,
    na = na,
    ...
  )

  cmd = sprintf("cat %s | bgzip -c > %s", tmp_path, path)
  ret = system(cmd)
  file.remove(tmp_path)

  if (ret != 0) {
    stop(sprintf("Command failed: %s", cmd))
  }
}
