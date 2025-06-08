#' Get gcloud command with proper path
#'
#' Finds and returns the gcloud command, checking common installation paths
#' if not found in PATH. Can be overridden with options(rgsutil.gcloud_path).
#'
#' @return Character string with the gcloud command path
#' @keywords internal
get_gcloud_cmd <- function() {
  # First check if user has set a custom path
  custom_path <- getOption("rgsutil.gcloud_path")
  if (!is.null(custom_path)) {
    return(custom_path)
  }

  # Check if gcloud is in PATH
  if (Sys.which("gcloud") != "") {
    return("gcloud")
  }

  # Common installation paths to check
  common_paths <- c(
    # macOS paths
    "/usr/local/bin/gcloud",
    "/opt/homebrew/bin/gcloud",
    "~/google-cloud-sdk/bin/gcloud",
    "/Applications/google-cloud-sdk/bin/gcloud",
    # Linux paths
    "/usr/bin/gcloud",
    "/snap/bin/gcloud",
    "~/snap/google-cloud-sdk/current/bin/gcloud",
    # Windows paths (though less common for this package)
    "C:/Program Files (x86)/Google/Cloud SDK/google-cloud-sdk/bin/gcloud",
    "C:/Program Files/Google/Cloud SDK/google-cloud-sdk/bin/gcloud"
  )

  # Expand paths and check existence
  for (path in common_paths) {
    expanded_path <- path.expand(path)
    if (file.exists(expanded_path)) {
      message(sprintf("Found gcloud at: %s", expanded_path))
      message("To avoid this check, set: options(rgsutil.gcloud_path = '%s')", expanded_path)
      return(expanded_path)
    }
  }

  # If still not found, provide helpful error
  stop(paste(
    "gcloud command not found. Please either:",
    "1. Install Google Cloud SDK: https://cloud.google.com/sdk/docs/install",
    "2. Add gcloud to your PATH",
    "3. Set the path explicitly: options(rgsutil.gcloud_path = '/path/to/gcloud')",
    sep = "\n"
  ))
}

#' Get default cache directory
#'
#' Returns the cache directory for storing downloaded files.
#' Can be overridden with options(rgsutil.cache_dir).
#'
#' @return Character string with the cache directory path
#' @keywords internal
#'
#' @details
#' Default cache directory selection:
#' 1. If rgsutil.cache_dir option is set, uses that
#' 2. Otherwise uses /tmp/rgsutil_cache on Unix-like systems
#' 3. Uses %TEMP%/rgsutil_cache on Windows
#'
#' The /tmp location provides a balance:
#' - Persists across R sessions (reduces GCS egress)
#' - Eventually cleaned by OS (prevents unbounded growth)
#' - No permission issues
#' - Clear location for users to manage
#'
#' For permanent cache: options(rgsutil.cache_dir = "~/my_cache")
#'
get_cache_dir <- function() {
  # First check for explicit cache directory
  cache_dir <- getOption("rgsutil.cache_dir")
  if (!is.null(cache_dir)) {
    expanded_dir <- path.expand(cache_dir)
    if (!dir.exists(expanded_dir)) {
      dir.create(expanded_dir, recursive = TRUE)
    }
    return(expanded_dir)
  }

  # Default: Use /tmp for Unix-like systems
  if (.Platform$OS.type == "windows") {
    default_dir <- file.path(Sys.getenv("TEMP"), "rgsutil_cache")
  } else {
    # Unix-like systems (macOS, Linux)
    default_dir <- "/tmp/rgsutil_cache"
  }

  # Try to create the directory
  tryCatch(
    {
      if (!dir.exists(default_dir)) {
        dir.create(default_dir, recursive = TRUE)
      }
      return(default_dir)
    },
    error = function(e) {
      # If we can't create the preferred directory, fall back to /tmp
      warning(sprintf("Could not create cache directory %s, using /tmp/rgsutil_cache", default_dir))
      fallback_dir <- "/tmp/rgsutil_cache"
      if (!dir.exists(fallback_dir)) {
        dir.create(fallback_dir, recursive = TRUE)
      }
      return(fallback_dir)
    }
  )
}

#' Configure rgsutil package options
#'
#' Sets package options for gcloud path and cache directory.
#'
#' @param gcloud_path Character string. Path to gcloud executable.
#' @param cache_dir Character string. Directory for caching downloaded files.
#'
#' @return NULL (invisibly). Called for side effects.
#'
#' @examples
#' \dontrun{
#' # Set custom gcloud path (useful for RStudio on macOS)
#' rgsutil_configure(gcloud_path = "/usr/local/bin/gcloud")
#'
#' # Set custom cache directory
#' rgsutil_configure(cache_dir = "~/my_gcs_cache")
#'
#' # Set both
#' rgsutil_configure(
#'   gcloud_path = "/opt/homebrew/bin/gcloud",
#'   cache_dir = "/var/tmp/rgsutil"
#' )
#' }
#'
#' @export
rgsutil_configure <- function(gcloud_path = NULL, cache_dir = NULL) {
  if (!is.null(gcloud_path)) {
    if (!file.exists(path.expand(gcloud_path))) {
      warning(sprintf("gcloud path does not exist: %s", gcloud_path))
    }
    options(rgsutil.gcloud_path = gcloud_path)
    message(sprintf("Set gcloud path to: %s", gcloud_path))
  }

  if (!is.null(cache_dir)) {
    expanded_dir <- path.expand(cache_dir)
    if (!dir.exists(expanded_dir)) {
      dir.create(expanded_dir, recursive = TRUE)
      message(sprintf("Created cache directory: %s", expanded_dir))
    }
    options(rgsutil.cache_dir = cache_dir)
    message(sprintf("Set cache directory to: %s", cache_dir))
  }

  invisible(NULL)
}

#' Show current rgsutil configuration
#'
#' Displays the current configuration for gcloud path and cache directory.
#'
#' @return NULL (invisibly). Prints configuration to console.
#'
#' @examples
#' \dontrun{
#' rgsutil_config_show()
#' }
#'
#' @export
rgsutil_config_show <- function() {
  gcloud <- tryCatch(
    get_gcloud_cmd(),
    error = function(e) "NOT FOUND"
  )

  cache <- get_cache_dir()

  cat("rgsutil configuration:\n")
  cat(sprintf("  gcloud path: %s\n", gcloud))
  cat(sprintf("  cache directory: %s\n", cache))
  cat("\nTo change these settings, use rgsutil_configure()\n")

  invisible(NULL)
}

#' Validate Google Storage path
#'
#' Checks if a Google Storage path is valid. A valid path must:
#' - Start with "gs://"
#' - Not contain spaces or special characters unless properly quoted
#'
#' @param path Character string. The Google Storage path to validate.
#' @param allow_multiple Logical. Whether to allow multiple paths (default FALSE).
#'
#' @return TRUE if valid, otherwise throws an error with descriptive message.
#' @keywords internal
#'
#' @details
#' This function validates Google Storage paths to catch common errors early.
#' It checks for:
#' - Correct "gs://" prefix
#' - Unquoted spaces (spaces are allowed if the entire path is quoted)
#' - Special characters that may cause issues with shell commands
#'
#' Special characters that are always forbidden: < > | & ; ` $ \\ newline
#' Characters that require quoting: space, !, ?, *, [, ], \{, \}, (, ), ', "
#'
validate_gs_path <- function(path, allow_multiple = FALSE) {
  if (length(path) == 0 || any(is.na(path))) {
    stop("Google Storage path cannot be empty or NA")
  }

  if (!allow_multiple && length(path) > 1) {
    stop("Multiple paths provided but only one expected")
  }

  # Check each path
  for (i in seq_along(path)) {
    p <- path[i]

    # Check for gs:// prefix
    if (!grepl("^gs://", p)) {
      stop(sprintf("Path must start with 'gs://': %s", p))
    }

    # Extract the path part after gs://
    path_part <- sub("^gs://", "", p)

    # Check if empty after gs://
    if (nchar(path_part) == 0) {
      stop("Path cannot be just 'gs://'")
    }

    # Check for always-forbidden characters (these can break shell commands)
    forbidden_chars <- c("<", ">", "|", "&", ";", "`", "$", "\\", "\n", "\r")
    for (char in forbidden_chars) {
      if (grepl(char, p, fixed = TRUE)) {
        stop(sprintf("Path contains forbidden character '%s': %s", char, p))
      }
    }

    # Check for spaces - they're OK if the path will be quoted, but warn
    if (grepl(" ", p)) {
      # Check if the path appears to be already quoted
      if (!(startsWith(p, '"') && endsWith(p, '"')) &&
        !(startsWith(p, "'") && endsWith(p, "'"))) {
        warning(sprintf("Path contains spaces and may need quoting: %s", p))
      }
    }

    # Check for other special characters that might need careful handling
    # These aren't forbidden but might cause issues
    special_chars <- c("!", "?", "*", "[", "]", "{", "}", "(", ")", "'", '"')
    special_found <- character(0)
    for (char in special_chars) {
      if (grepl(char, p, fixed = TRUE)) {
        special_found <- c(special_found, char)
      }
    }

    if (length(special_found) > 0) {
      # Don't error, but inform that special handling may be needed
      message(sprintf(
        "Path contains special characters (%s) that may require quoting: %s",
        paste(special_found, collapse = ", "), p
      ))
    }
  }

  return(TRUE)
}
