#' Enhanced file writer with BGZ compression support
#'
#' A wrapper around \code{\link[data.table]{fwrite}} that automatically handles
#' BGZ compression for genomics data files. Creates parent directories as needed.
#'
#' @param x A data.frame or data.table to write.
#' @param path Character string. The path where the file should be written.
#'   If the path ends with .bgz, the file will be compressed using bgzip.
#' @param sep Character string. Field separator. Defaults to "\\t" (tab).
#' @param na Character string. String to use for missing values. Defaults to "NA".
#' @param ... Additional arguments passed to \code{\link[data.table]{fwrite}}.
#'
#' @return NULL (invisibly). The function is called for its side effect of
#'   writing a file.
#'
#' @details
#' This function enhances data.table::fwrite by:
#' \itemize{
#'   \item Automatically creating parent directories if they don't exist
#'   \item Supporting BGZ compression (commonly used in genomics) for .bgz files
#'   \item Setting sensible defaults for genomics data (tab-separated, no quotes)
#' }
#'
#' For BGZ files, the function:
#' \enumerate{
#'   \item Writes to a temporary file first
#'   \item Compresses using bgzip
#'   \item Removes the temporary file
#' }
#'
#' @note
#' BGZ compression requires the \code{bgzip} command to be available in the system PATH.
#' This is typically installed with htslib or samtools.
#'
#' @examples
#' \dontrun{
#' # Write a regular TSV file
#' df <- data.frame(chr = c("chr1", "chr2"), pos = c(100, 200))
#' fwrite_wrapper(df, "output.tsv")
#'
#' # Write a BGZ compressed file for genomics data
#' fwrite_wrapper(df, "output.tsv.bgz")
#'
#' # Write CSV format
#' fwrite_wrapper(df, "output.csv", sep = ",")
#' }
#'
#' @seealso \code{\link{write_gsfile}}, \code{\link[data.table]{fwrite}},
#'   \code{\link{fread_wrapper}}
#'
#' @importFrom data.table fwrite
fwrite_wrapper <- function(x,
                           path,
                           sep = "\t",
                           na = "NA",
                           ...) {
  dest_dir <- dirname(path)
  if (!dir.exists(dest_dir)) {
    dir.create(dest_dir, recursive = TRUE)
  }

  is_bgz <- tools::file_ext(path) == "bgz"
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

  tmp_path <- paste0(path, "-tmp")
  data.table::fwrite(
    x,
    tmp_path,
    quote = FALSE,
    row.names = FALSE,
    sep = sep,
    na = na,
    ...
  )

  cmd <- sprintf("cat %s | bgzip -c > %s", tmp_path, path)
  ret <- system(cmd)
  file.remove(tmp_path)

  if (ret != 0) {
    stop(sprintf("Command failed: %s", cmd))
  }
}
