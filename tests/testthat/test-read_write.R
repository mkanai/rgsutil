test_that("read_gsfile works with gnomAD data", {
  skip_if_offline()
  skip_if_not(nzchar(Sys.which("gcloud")), "gcloud not available")

  # Test file from gnomAD public data
  test_file <- "gs://gcp-public-data--gnomad/release/4.1/tsv/exomes/gnomad.exomes.v4.1.de_novo.high_quality_coding.tsv.bgz"

  # Read the file
  expect_no_error({
    df <- read_gsfile(test_file, nrows = 10) # Read only first 10 rows for speed
  })

  # Check the result
  expect_true(is.data.frame(df))
  expect_true(nrow(df) > 0)
  expect_true(ncol(df) > 0)

  # Test caching - second read should use cache
  expect_message(
    {
      df2 <- read_gsfile(test_file, nrows = 10)
    },
    "Using a cache"
  )

  expect_identical(df, df2)
})

test_that("read_gsfile validates paths", {
  # Invalid paths should error
  expect_error(read_gsfile("not-a-gs-path"), "Path must start with 'gs://'")
  expect_error(read_gsfile("gs://"), "Path cannot be just 'gs://'")
  expect_error(read_gsfile("gs://bucket/file|pipe.txt"), "forbidden character")
})

test_that("read_gsfiles works with patterns", {
  skip_if_offline()
  skip_if_not(nzchar(Sys.which("gcloud")), "gcloud not available")

  # Test with a specific file (not pattern) to ensure predictable results
  test_file <- "gs://gcp-public-data--gnomad/release/4.1/tsv/exomes/gnomad.exomes.v4.1.de_novo.high_quality_coding.tsv.bgz"

  # Read single file as a list
  expect_no_error({
    result_list <- read_gsfiles(test_file, nrows = 5, combine = "none")
  })

  expect_true(is.list(result_list))
  expect_equal(length(result_list), 1)
  expect_true(is.data.frame(result_list[[1]]))

  # Read with row combination
  expect_no_error({
    result_df <- read_gsfiles(test_file, nrows = 5, combine = "rows")
  })

  expect_true(is.data.frame(result_df))
  expect_equal(nrow(result_df), 5)
})

test_that("read_gsfiles validates paths", {
  # Invalid paths should error
  expect_error(
    read_gsfiles(c("gs://valid/path.txt", "not-gs-path")),
    "Path must start with 'gs://'"
  )
  expect_error(
    read_gsfiles("gs://bucket/file;semicolon.txt"),
    "forbidden character"
  )
})

test_that("map_dfr_gsfiles is a wrapper for read_gsfiles", {
  skip_if_offline()
  skip_if_not(nzchar(Sys.which("gcloud")), "gcloud not available")

  test_file <- "gs://gcp-public-data--gnomad/release/4.1/tsv/exomes/gnomad.exomes.v4.1.de_novo.high_quality_coding.tsv.bgz"

  # map_dfr_gsfiles should combine rows by default
  expect_no_error({
    df <- map_dfr_gsfiles(test_file,
      func = function(d, path) {
        d$source <- basename(path)
        return(d)
      },
      nrows = 5
    )
  })

  expect_true(is.data.frame(df))
  expect_true("source" %in% names(df))
  expect_equal(nrow(df), 5)
})

test_that("map_dfc_gsfiles is a wrapper for read_gsfiles with columns", {
  skip_if_offline()
  skip_if_not(nzchar(Sys.which("gcloud")), "gcloud not available")

  test_file <- "gs://gcp-public-data--gnomad/release/4.1/tsv/exomes/gnomad.exomes.v4.1.de_novo.high_quality_coding.tsv.bgz"

  # First test with single file - should still work
  expect_no_error({
    df <- map_dfc_gsfiles(test_file,
      func = function(d, path) {
        # Return a data frame with the locus column
        data.frame(test_col = d$locus[1:min(5, nrow(d))], stringsAsFactors = FALSE)
      },
      nrows = 5
    )
  })

  expect_true(is.data.frame(df))
  expect_equal(nrow(df), 5)
  expect_equal(ncol(df), 1)
  expect_true("test_col" %in% names(df))
})

test_that("write_gsfile works with mocking", {
  # Create a temporary test data frame
  test_df <- data.frame(
    id = 1:5,
    value = letters[1:5],
    stringsAsFactors = FALSE
  )

  # Create a test environment to override functions
  test_env <- new.env()

  # Track if upload_gsfile was called
  upload_called <- FALSE
  local_path_used <- NULL

  # Override upload_gsfile to avoid actual uploads
  test_env$upload_gsfile <- function(local_path, remote_path) {
    upload_called <<- TRUE
    local_path_used <<- local_path
    # Check that local file was created
    expect_true(file.exists(local_path))
    # Read it to verify content
    written_df <- data.table::fread(local_path)
    expect_equal(nrow(written_df), 5)
    expect_equal(ncol(written_df), 2)
    # Simulate successful upload
    return(invisible(NULL))
  }

  # Override gsfile_exists to return FALSE (file doesn't exist)
  test_env$gsfile_exists <- function(remote_path) {
    return(FALSE)
  }

  # Temporarily replace the functions
  old_upload <- rgsutil:::upload_gsfile
  old_exists <- rgsutil:::gsfile_exists

  assignInNamespace("upload_gsfile", test_env$upload_gsfile, "rgsutil")
  assignInNamespace("gsfile_exists", test_env$gsfile_exists, "rgsutil")

  # Test writing
  tryCatch({
    expect_no_error({
      write_gsfile(test_df, "gs://test-bucket/test-file.tsv")
    })

    # Verify upload was called
    expect_true(upload_called)

    # Clean up the local file if it still exists
    if (!is.null(local_path_used) && file.exists(local_path_used)) {
      unlink(local_path_used)
    }
  }, finally = {
    # Restore original functions
    assignInNamespace("upload_gsfile", old_upload, "rgsutil")
    assignInNamespace("gsfile_exists", old_exists, "rgsutil")
  })
})

test_that("write_gsfile validates paths", {
  test_df <- data.frame(x = 1:3)

  # Invalid paths should error
  expect_error(
    write_gsfile(test_df, "not-a-gs-path"),
    "Path must start with 'gs://'"
  )
  expect_error(
    write_gsfile(test_df, "gs://bucket/file|pipe.txt"),
    "forbidden character"
  )
})

test_that("write_gsfile respects overwrite parameter", {
  test_df <- data.frame(x = 1:3)

  # Create a test environment
  test_env <- new.env()

  # Track gsfile_exists calls
  test_env$exists_return_value <- TRUE

  # Override gsfile_exists
  test_env$gsfile_exists <- function(remote_path) {
    return(test_env$exists_return_value)
  }

  # Override upload_gsfile
  test_env$upload_gsfile <- function(local_path, remote_path) {
    # Clean up the local file
    if (file.exists(local_path)) {
      unlink(local_path)
    }
    return(invisible(NULL))
  }

  # Save original functions
  old_exists <- rgsutil:::gsfile_exists
  old_upload <- rgsutil:::upload_gsfile

  # Replace functions
  assignInNamespace("gsfile_exists", test_env$gsfile_exists, "rgsutil")
  assignInNamespace("upload_gsfile", test_env$upload_gsfile, "rgsutil")

  tryCatch({
    # Should error when overwrite = FALSE (default) and file exists
    expect_error(
      write_gsfile(test_df, "gs://test-bucket/existing.tsv"),
      "Remote file exists"
    )

    # Should succeed with overwrite = TRUE
    suppressWarnings({
      expect_message(
        {
          write_gsfile(test_df, "gs://test-bucket/existing.tsv", overwrite = TRUE)
        },
        "overwrites a remote file"
      )
    })

    # Test when file doesn't exist
    test_env$exists_return_value <- FALSE
    suppressWarnings({
      expect_no_error({
        write_gsfile(test_df, "gs://test-bucket/new-file.tsv")
      })
    })
  }, finally = {
    # Restore original functions
    assignInNamespace("gsfile_exists", old_exists, "rgsutil")
    assignInNamespace("upload_gsfile", old_upload, "rgsutil")
  })
})
