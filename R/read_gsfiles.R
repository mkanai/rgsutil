#' Read multiple files from Google Cloud Storage
#'
#' Downloads and reads multiple files from Google Cloud Storage matching patterns.
#' Optimizes performance by batch downloading files before reading.
#'
#' @param remote_pattern Character string or vector. Google Cloud Storage paths or patterns
#'   starting with "gs://". Accepts:
#'   \itemize{
#'     \item Single pattern: \code{"gs://bucket/data/*.csv"}
#'     \item Vector of paths: \code{c("gs://bucket/file1.csv", "gs://bucket/file2.csv")}
#'     \item Brace expansion: \code{"gs://bucket/data/{jan,feb,mar}.csv"}
#'     \item Mixed patterns: \code{c("gs://bucket/2023/*.csv", "gs://bucket/2024/*.csv")}
#'   }
#' @param func Function. Optional function to apply to each file after reading.
#'   Must accept two arguments: \code{df} (the data frame) and \code{path} (the GS file path).
#'   Example: \code{function(df, path) \{ df$source <- basename(path); return(df) \}}.
#'   If NULL, returns raw data frames.
#' @param combine Character string. How to combine results: "none" (list),
#'   "rows" (rbind), or "cols" (cbind). Defaults to "none".
#' @param cache.dir Character string. Directory for caching downloaded files.
#'   Defaults to getOption("rgsutil.cache_dir") or a temp directory.
#' @param parallel Logical or integer. Whether to read files in parallel using future.
#'   If TRUE, uses all available cores. If integer, uses that many cores. Defaults to FALSE.
#' @param .progress Logical. Whether to show progress messages. Defaults to TRUE.
#' @param ... Additional arguments passed to \code{\link{fread_wrapper}} for each file.
#'
#' @return Depending on the \code{combine} parameter:
#'   \itemize{
#'     \item "none": A named list of data frames (names are file paths)
#'     \item "rows": A single data frame with all rows combined
#'     \item "cols": A single data frame with all columns combined
#'   }
#'
#' @details
#' This function optimizes reading multiple files by:
#' \enumerate{
#'   \item Listing all files matching the patterns using gcloud's native pattern expansion
#'   \item Checking which files need updating (if cached)
#'   \item Batch downloading all required files using gcloud's native parallel support
#'   \item Reading and optionally processing each file (optionally in parallel)
#'   \item Combining results based on the specified method
#' }
#'
#' The \code{func} parameter allows custom processing of each file. The function
#' must accept exactly two arguments: \code{df} (the data frame read from the file)
#' and \code{path} (the full GS path of the file, e.g., "gs://bucket/file.csv").
#' The function should return a data frame. This is useful for adding metadata,
#' filtering data, or extracting information from the file path.
#'
#' When \code{parallel = TRUE}, the package will use the \code{furrr}
#' package for parallel reading. Install \code{furrr} and \code{future}
#' packages to enable parallel processing. For sequential processing with
#' progress bars, install the \code{purrr} package.
#'
#' @examples
#' \dontrun{
#' # Read all CSV files and return a list
#' data_list <- read_gsfiles("gs://my-bucket/data/*.csv")
#'
#' # Read specific files
#' specific_files <- read_gsfiles(c(
#'   "gs://my-bucket/data/file1.csv",
#'   "gs://my-bucket/data/file2.csv",
#'   "gs://my-bucket/data/file3.csv"
#' ))
#'
#' # Use brace expansion for months
#' monthly_data <- read_gsfiles(
#'   "gs://my-bucket/reports/2024-{01,02,03,04,05,06}.csv",
#'   combine = "rows"
#' )
#'
#' # Or more concisely for named months
#' quarterly_data <- read_gsfiles(
#'   "gs://my-bucket/reports/2024-{jan,feb,mar}.csv",
#'   combine = "rows"
#' )
#'
#' # Nested brace expansion for multiple years and months
#' historical_data <- read_gsfiles(
#'   "gs://my-bucket/reports/{2022,2023,2024}-{jan,feb,mar}.csv",
#'   combine = "rows"
#' )
#'
#' # Mix different patterns
#' all_data <- read_gsfiles(c(
#'   "gs://my-bucket/2023/*.csv",
#'   "gs://my-bucket/2024/*.csv",
#'   "gs://my-bucket/archive/backup-*.csv"
#' ), combine = "rows")
#'
#' # Add source file information to each data frame
#' with_source <- read_gsfiles(
#'   "gs://my-bucket/logs/2024-*.txt",
#'   func = function(df, path) {
#'     df$source_file <- basename(path)
#'     df$date <- as.Date(gsub(".*-(\\d{4}-\\d{2}-\\d{2})\\.txt", "\\1", path))
#'     return(df)
#'   },
#'   combine = "rows"
#' )
#'
#' # Process genomics files with filtering
#' variants <- read_gsfiles(
#'   "gs://genomics/chr*.vcf.bgz",
#'   func = function(df, path) {
#'     df %>%
#'       filter(QUAL > 30) %>%
#'       mutate(chromosome = gsub(".*chr(\\w+)\\..*", "\\1", basename(path)))
#'   },
#'   combine = "rows",
#'   sep = "\t"
#' )
#'
#' # Use parallel processing for faster reading
#' # Requires: install.packages(c("furrr", "future"))
#' large_dataset <- read_gsfiles(
#'   "gs://my-bucket/big-data/*.parquet",
#'   parallel = TRUE, # Use all available cores
#'   combine = "rows"
#' )
#'
#' # Specify number of parallel workers
#' results <- read_gsfiles(
#'   "gs://my-bucket/data/file*.csv",
#'   parallel = 4, # Use 4 cores
#'   func = function(df, path) {
#'     # Complex processing that benefits from parallelization
#'     df %>%
#'       group_by(category) %>%
#'       summarise(mean_value = mean(value, na.rm = TRUE))
#'   }
#' )
#' }
#'
#' @seealso \code{\link{read_gsfile}}, \code{\link{list_gsfile}}
#'
#' @export
read_gsfiles <- function(remote_pattern,
                         func = NULL,
                         combine = c("none", "rows", "cols"),
                         cache.dir = NULL,
                         parallel = FALSE,
                         .progress = TRUE,
                         ...) {
  combine <- match.arg(combine)

  # Ensure remote_pattern is a character vector
  if (!is.character(remote_pattern)) {
    stop("remote_pattern must be a character string or vector")
  }

  # Validate all patterns
  validate_gs_path(remote_pattern, allow_multiple = TRUE)

  # Use configured cache directory if not specified
  if (is.null(cache.dir)) {
    cache.dir <- get_cache_dir()
  }

  # List all files matching the patterns
  # gcloud storage ls handles all pattern expansion automatically
  if (.progress) message("Listing files matching patterns...")
  remote_files <- list_gsfile(remote_pattern)

  if (length(remote_files) == 0) {
    warning("No files found matching pattern(s): ", paste(remote_pattern, collapse = ", "))
    return(if (combine == "none") list() else data.frame())
  }

  if (.progress) {
    message(sprintf("Found %d files", length(remote_files)))
  }

  # Prepare local paths
  local_paths <- file.path(
    cache.dir,
    substring(remote_files, 6) # Remove "gs://"
  )

  # Check which files need updating
  files_to_download <- character()
  files_to_download_indices <- integer()

  for (i in seq_along(remote_files)) {
    if (!file.exists(local_paths[i])) {
      files_to_download <- c(files_to_download, remote_files[i])
      files_to_download_indices <- c(files_to_download_indices, i)
    } else {
      # Check if update needed
      update_needed <- tryCatch(
        {
          check_update(remote_files[i], local_paths[i])
        },
        error = function(e) {
          TRUE # If check fails, assume update needed
        }
      )

      if (update_needed) {
        files_to_download <- c(files_to_download, remote_files[i])
        files_to_download_indices <- c(files_to_download_indices, i)
      }
    }
  }

  # Batch download if needed
  if (length(files_to_download) > 0) {
    if (.progress) {
      message(sprintf("Downloading %d files...", length(files_to_download)))
    }

    # Strategy: Use gcloud's native multi-file support
    # If files are in different directories, we use a staging directory
    unique_remote_dirs <- unique(dirname(files_to_download))

    if (length(unique_remote_dirs) == 1) {
      # All files in same directory - direct download
      local_dir <- file.path(cache.dir, substring(unique_remote_dirs[1], 6))
      if (!dir.exists(local_dir)) {
        dir.create(local_dir, recursive = TRUE)
      }

      # Use gcloud's native parallel download
      gcloud_cmd <- get_gcloud_cmd()
      cmd <- sprintf(
        "%s storage cp %s %s/",
        gcloud_cmd,
        paste(shQuote(files_to_download), collapse = " "),
        shQuote(local_dir)
      )
      ret <- system(cmd)
      if (ret != 0) {
        stop("Batch download failed")
      }
    } else {
      # Files in different directories - smart hybrid approach
      # Separate files with unique vs non-unique basenames
      basenames <- basename(files_to_download)
      basename_counts <- table(basenames)

      unique_basename_files <- files_to_download[basenames %in% names(basename_counts)[basename_counts == 1]]
      duplicate_basename_files <- files_to_download[basenames %in% names(basename_counts)[basename_counts > 1]]

      # Batch download files with unique basenames to staging
      if (length(unique_basename_files) > 0) {
        staging_dir <- file.path(
          cache.dir, ".rgsutil_staging",
          format(Sys.time(), "%Y%m%d_%H%M%S")
        )
        if (!dir.exists(staging_dir)) {
          dir.create(staging_dir, recursive = TRUE)
        }

        # Batch download all unique-basename files
        gcloud_cmd <- get_gcloud_cmd()
        cmd <- sprintf(
          "%s storage cp %s %s/",
          gcloud_cmd,
          paste(shQuote(unique_basename_files), collapse = " "),
          shQuote(staging_dir)
        )
        ret <- system(cmd)
        if (ret != 0) {
          stop("Batch download failed")
        }

        # Move files from staging to correct locations
        for (file in unique_basename_files) {
          idx <- which(files_to_download == file)
          staged_file <- file.path(staging_dir, basename(file))
          target_file <- local_paths[files_to_download_indices[idx]]
          target_dir <- dirname(target_file)

          if (!dir.exists(target_dir)) {
            dir.create(target_dir, recursive = TRUE)
          }

          file.rename(staged_file, target_file)
        }

        # Clean up staging directory
        unlink(staging_dir, recursive = TRUE)
      }

      # Download files with duplicate basenames individually
      if (length(duplicate_basename_files) > 0) {
        for (file in duplicate_basename_files) {
          idx <- which(files_to_download == file)
          target_file <- local_paths[files_to_download_indices[idx]]
          target_dir <- dirname(target_file)

          if (!dir.exists(target_dir)) {
            dir.create(target_dir, recursive = TRUE)
          }

          gcloud_cmd <- get_gcloud_cmd()
          cmd <- sprintf(
            "%s storage cp %s %s",
            gcloud_cmd,
            shQuote(file),
            shQuote(target_file)
          )
          ret <- system(cmd, ignore.stdout = TRUE)
          if (ret != 0) {
            stop(sprintf("Failed to download: %s", file))
          }
        }
      }
    }

    if (.progress) message("Download complete")
  } else {
    if (.progress) message("All files are cached and up to date")
  }

  # Read all files
  if (.progress) message("Reading files...")

  # Check if parallel processing is requested
  use_parallel <- FALSE
  if (!isFALSE(parallel)) {
    # Check if furrr is available for parallel processing
    if (requireNamespace("furrr", quietly = TRUE) &&
      requireNamespace("future", quietly = TRUE)) {
      use_parallel <- TRUE

      # Set up future plan
      if (isTRUE(parallel)) {
        # Use all available cores
        future::plan(future::multisession)
      } else if (is.numeric(parallel) && parallel > 1) {
        # Use specified number of cores
        future::plan(future::multisession, workers = as.integer(parallel))
      } else {
        use_parallel <- FALSE
      }

      if (use_parallel && .progress) {
        message(sprintf(
          "Using parallel processing with %d workers",
          future::nbrOfWorkers()
        ))
      }
    } else {
      if (.progress) {
        message("Note: Install 'furrr' and 'future' packages for parallel processing")
      }
    }
  }

  # Function to read and process a single file
  read_single_file <- function(i) {
    df <- tryCatch(
      {
        # Always read from local cache (we've already downloaded all files)
        fread_wrapper(local_paths[i], ...)
      },
      error = function(e) {
        stop(sprintf("Failed to read file %s: %s", remote_files[i], e$message))
      }
    )

    # Apply processing function if provided
    if (!is.null(func)) {
      df <- tryCatch(
        {
          func(df, remote_files[i])
        },
        error = function(e) {
          stop(sprintf("Failed to process file %s: %s", remote_files[i], e$message))
        }
      )
    }

    return(df)
  }

  # Read files either in parallel or sequentially
  if (use_parallel) {
    # Use furrr for parallel processing with progress bar
    results <- furrr::future_map(
      seq_along(remote_files),
      read_single_file,
      .progress = .progress,
      .options = furrr::furrr_options(seed = TRUE)
    )
    # Reset future plan
    future::plan(future::sequential)
  } else if (requireNamespace("purrr", quietly = TRUE)) {
    # Use purrr for sequential processing with progress bar
    results <- purrr::map(
      seq_along(remote_files),
      read_single_file,
      .progress = .progress
    )
  } else {
    # Fall back to base R lapply without progress bar
    results <- lapply(seq_along(remote_files), read_single_file)
  }

  names(results) <- remote_files

  # Combine results if requested
  if (combine == "rows") {
    if (.progress) message("Combining rows...")
    combined <- do.call(rbind, results)
    rownames(combined) <- NULL
    return(combined)
  } else if (combine == "cols") {
    if (.progress) message("Combining columns...")
    return(do.call(cbind, results))
  } else {
    return(results)
  }
}

#' @rdname read_gsfiles
#' @export
map_dfr_gsfiles <- function(remote_pattern, func, ...) {
  read_gsfiles(remote_pattern, func = func, combine = "rows", ...)
}

#' @rdname read_gsfiles
#' @export
map_dfc_gsfiles <- function(remote_pattern, func, ...) {
  read_gsfiles(remote_pattern, func = func, combine = "cols", ...)
}
