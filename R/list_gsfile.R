#' List files in Google Cloud Storage
#'
#' Lists files and objects at the specified Google Cloud Storage path.
#' Can list both individual files and contents of directories.
#'
#' @param remote_path Character string. The Google Cloud Storage path to list,
#'   must start with "gs://". Can be a specific file, directory, or pattern.
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
  suppressWarnings({
    files <- system(
      paste("gcloud storage ls", remote_path),
      intern = TRUE,
      ignore.stderr = TRUE
    )
  })
  return(files)
}
