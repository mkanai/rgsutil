#' List files in Google Cloud Storage
#'
#' Lists files and objects at the specified Google Cloud Storage paths.
#' Can list individual files, directories, patterns, or multiple paths at once.
#'
#' @param remote_path Character string or vector. Google Cloud Storage paths to list.
#'   Each must start with "gs://". Can be specific files, directories, patterns,
#'   or brace expansions.
#'
#' @return Character vector of file paths found at the specified location.
#'   Returns an empty vector if no files are found.
#'
#' @details
#' This function uses the \code{gcloud storage ls} command to list files.
#' It can be used to:
#' \itemize{
#'   \item List all files in a bucket: \code{"gs://my-bucket/"}
#'   \item List files in a directory: \code{"gs://my-bucket/data/"}
#'   \item Check for specific files: \code{"gs://my-bucket/data/file.csv"}
#'   \item Use wildcards: \code{"gs://my-bucket/data/*.csv"}
#'   \item Use brace expansion: \code{"gs://my-bucket/data/file{1,2,3}.csv"}
#'   \item List multiple paths: \code{c("gs://bucket1/*.csv", "gs://bucket2/*.csv")}
#' }
#'
#' @note
#' The function suppresses stderr output from the gcloud command, so error
#' messages (e.g., for non-existent paths) will not be displayed.
#'
#' @examples
#' \dontrun{
#' # List all files in a directory
#' files <- list_gsfile("gs://my-bucket/data/")
#'
#' # List CSV files using a pattern
#' csv_files <- list_gsfile("gs://my-bucket/data/*.csv")
#'
#' # Use brace expansion
#' monthly_files <- list_gsfile("gs://my-bucket/reports/2024-{01,02,03}.csv")
#'
#' # List multiple patterns at once
#' all_files <- list_gsfile(c(
#'   "gs://my-bucket/2023/*.csv",
#'   "gs://my-bucket/2024/*.csv"
#' ))
#'
#' # Check if any files exist in a location
#' if (length(list_gsfile("gs://my-bucket/output/")) == 0) {
#'   message("No output files found")
#' }
#' }
#'
#' @seealso \code{\link{gsfile_exists}}, \code{\link{download_gsfile}}
#'
#' @export
#'
list_gsfile <- function(remote_path) {
  validate_gs_path(remote_path, allow_multiple = TRUE)

  # Get gcloud command
  gcloud_cmd <- get_gcloud_cmd()

  # Handle multiple paths/patterns
  all_files <- character()

  for (path in remote_path) {
    suppressWarnings({
      files <- system(
        paste(gcloud_cmd, "storage ls", shQuote(path)),
        intern = TRUE,
        ignore.stderr = TRUE
      )
    })
    all_files <- c(all_files, files)
  }

  # Remove duplicates and return
  return(unique(all_files))
}
