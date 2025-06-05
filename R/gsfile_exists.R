#' Check if a file exists in Google Cloud Storage
#'
#' Tests whether a file or object exists at the specified Google Cloud Storage path.
#'
#' @param remote_path Character string. The Google Cloud Storage path to check,
#'   must start with "gs://".
#'
#' @return Logical. TRUE if the file exists, FALSE otherwise.
#'
#' @details
#' This function uses \code{\link{list_gsfile}} to check for the existence of
#' a file. It returns TRUE if at least one file matches the given path.
#'
#' @examples
#' \dontrun{
#' # Check if a specific file exists
#' if (gsfile_exists("gs://my-bucket/data/file.csv")) {
#'   message("File exists")
#' }
#'
#' # Use in conditional logic
#' remote_file <- "gs://my-bucket/data/results.tsv"
#' if (!gsfile_exists(remote_file)) {
#'   stop("Required file not found: ", remote_file)
#' }
#' }
#'
#' @seealso \code{\link{list_gsfile}}, \code{\link{write_gsfile}}
#'
#' @export
#'
gsfile_exists <- function(remote_path) {
  files <- list_gsfile(remote_path)
  return(length(files) > 0)
}
