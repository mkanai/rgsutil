test_that("list_gsfile works with public data", {
  skip_if_offline()
  skip_if_not(nzchar(Sys.which("gcloud")), "gcloud not available")

  # List files in gnomAD directory
  files <- list_gsfile("gs://gcp-public-data--gnomad/release/4.1/tsv/exomes/")

  expect_true(is.character(files))
  expect_true(length(files) > 0)
  # Filter out any non-gs:// lines (e.g., headers or empty lines)
  gs_files <- files[startsWith(files, "gs://")]
  expect_true(length(gs_files) > 0)
  expect_true(all(startsWith(gs_files, "gs://")))

  # Test with specific file
  specific_file <- list_gsfile("gs://gcp-public-data--gnomad/release/4.1/tsv/exomes/gnomad.exomes.v4.1.de_novo.high_quality_coding.tsv.bgz")
  expect_equal(length(specific_file), 1)
})

test_that("list_gsfile validates paths", {
  expect_error(list_gsfile("not-a-gs-path"), "Path must start with 'gs://'")
  expect_error(list_gsfile("gs://bucket/file|pipe.txt"), "forbidden character")
})

test_that("list_gsfile handles multiple paths", {
  skip_if_offline()
  skip_if_not(nzchar(Sys.which("gcloud")), "gcloud not available")

  # Test with multiple specific files
  files <- list_gsfile(c(
    "gs://gcp-public-data--gnomad/release/4.1/tsv/exomes/gnomad.exomes.v4.1.de_novo.high_quality_coding.tsv.bgz",
    "gs://gcp-public-data--gnomad/release/4.1/tsv/exomes/gnomad.exomes.v4.1.de_novo.high_quality_coding.tsv.bgz"
  ))

  # Should return unique results
  expect_equal(length(files), 1)
})

test_that("gsfile_exists works correctly", {
  skip_if_offline()
  skip_if_not(nzchar(Sys.which("gcloud")), "gcloud not available")

  # Test with known existing file
  expect_true(gsfile_exists("gs://gcp-public-data--gnomad/release/4.1/tsv/exomes/gnomad.exomes.v4.1.de_novo.high_quality_coding.tsv.bgz"))

  # Test with non-existing file
  expect_false(gsfile_exists("gs://gcp-public-data--gnomad/this-file-does-not-exist-12345.txt"))
})

test_that("check_update works with valid files", {
  skip_if_offline()
  skip_if_not(nzchar(Sys.which("gcloud")), "gcloud not available")

  # First, download a file to create a local copy
  test_file <- "gs://gcp-public-data--gnomad/release/4.1/tsv/exomes/gnomad.exomes.v4.1.de_novo.high_quality_coding.tsv.bgz"
  temp_dir <- tempdir()
  local_file <- file.path(temp_dir, "test_file.tsv.bgz")

  # Mock download to create a local file
  writeLines("test content", local_file)

  # check_update should work (remote file will be newer than just-created local)
  expect_true(is.logical(check_update(test_file, local_file)))

  # Clean up
  unlink(local_file)
})

test_that("check_update validates paths", {
  expect_error(
    check_update("not-a-gs-path", "/tmp/file.txt"),
    "Path must start with 'gs://'"
  )
  expect_error(
    check_update("gs://bucket/file;semicolon.txt", "/tmp/file.txt"),
    "forbidden character"
  )
})

test_that("download_gsfile validates paths", {
  expect_error(
    download_gsfile("not-a-gs-path", tempdir()),
    "Path must start with 'gs://'"
  )
  expect_error(
    download_gsfile("gs://bucket/file|pipe.txt", tempdir()),
    "forbidden character"
  )
})

test_that("download_gsfile creates destination directory", {
  skip_if_offline()
  skip_if_not(nzchar(Sys.which("gcloud")), "gcloud not available")

  # Create a nested temp directory path that doesn't exist
  test_dir <- file.path(tempdir(), "rgsutil_test", "nested", "dir")

  # Clean up if it exists from previous run
  if (dir.exists(dirname(dirname(test_dir)))) {
    unlink(dirname(dirname(test_dir)), recursive = TRUE)
  }

  # Download a small file
  test_file <- "gs://gcp-public-data--gnomad/release/4.1/tsv/exomes/gnomad.exomes.v4.1.de_novo.high_quality_coding.tsv.bgz"

  expect_no_error({
    download_gsfile(test_file, test_dir)
  })

  # Check directory was created
  expect_true(dir.exists(test_dir))

  # Check file was downloaded
  downloaded_file <- file.path(test_dir, basename(test_file))
  expect_true(file.exists(downloaded_file))

  # Clean up
  unlink(dirname(dirname(test_dir)), recursive = TRUE)
})

test_that("upload_gsfile validates paths", {
  temp_file <- tempfile()
  writeLines("test", temp_file)

  expect_error(
    upload_gsfile(temp_file, "not-a-gs-path"),
    "Path must start with 'gs://'"
  )
  expect_error(
    upload_gsfile(temp_file, "gs://bucket/file&ampersand.txt"),
    "forbidden character"
  )

  unlink(temp_file)
})
