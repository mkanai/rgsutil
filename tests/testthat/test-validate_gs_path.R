# Tests for validate_gs_path function
# Note: These tests require testthat package to be installed

test_that("validate_gs_path validates correct paths", {
  # Single valid path
  expect_true(validate_gs_path("gs://bucket/file.txt"))
  expect_true(validate_gs_path("gs://bucket/dir/file.txt"))
  expect_true(validate_gs_path("gs://bucket-name/file_name.txt"))

  # Multiple valid paths
  expect_true(validate_gs_path(c("gs://bucket1/file.txt", "gs://bucket2/file.txt"),
    allow_multiple = TRUE
  ))
})

test_that("validate_gs_path rejects invalid paths", {
  # Missing gs:// prefix
  expect_error(
    validate_gs_path("bucket/file.txt"),
    "Path must start with 'gs://'"
  )
  expect_error(
    validate_gs_path("s3://bucket/file.txt"),
    "Path must start with 'gs://'"
  )

  # Empty or NA paths
  expect_error(
    validate_gs_path(""),
    "Google Storage path cannot be empty or NA"
  )
  expect_error(
    validate_gs_path(NA),
    "Google Storage path cannot be empty or NA"
  )
  expect_error(
    validate_gs_path(character(0)),
    "Google Storage path cannot be empty or NA"
  )

  # Just gs://
  expect_error(
    validate_gs_path("gs://"),
    "Path cannot be just 'gs://'"
  )

  # Multiple paths when not allowed
  expect_error(
    validate_gs_path(c("gs://bucket1/file.txt", "gs://bucket2/file.txt")),
    "Multiple paths provided but only one expected"
  )
})

test_that("validate_gs_path detects forbidden characters", {
  # Always forbidden characters
  expect_error(
    validate_gs_path("gs://bucket/file|pipe.txt"),
    "Path contains forbidden character '\\|'"
  )
  expect_error(
    validate_gs_path("gs://bucket/file&amp.txt"),
    "Path contains forbidden character '&'"
  )
  expect_error(
    validate_gs_path("gs://bucket/file;semicolon.txt"),
    "Path contains forbidden character ';'"
  )
  expect_error(
    validate_gs_path("gs://bucket/file`backtick.txt"),
    "Path contains forbidden character '`'"
  )
  expect_error(
    validate_gs_path("gs://bucket/file$dollar.txt"),
    "Path contains forbidden character '\\$'"
  )
  expect_error(
    validate_gs_path("gs://bucket/file<less.txt"),
    "Path contains forbidden character '<'"
  )
  expect_error(
    validate_gs_path("gs://bucket/file>greater.txt"),
    "Path contains forbidden character '>'"
  )
  expect_error(
    validate_gs_path("gs://bucket/file\\backslash.txt"),
    "Path contains forbidden character '\\\\'"
  )
  expect_error(
    validate_gs_path("gs://bucket/file\nline.txt"),
    "Path contains forbidden character"
  )
})

test_that("validate_gs_path warns about spaces", {
  # Unquoted spaces should warn
  expect_warning(
    validate_gs_path("gs://bucket/file with spaces.txt"),
    "Path contains spaces and may need quoting"
  )

  # Note: Quoted paths are not automatically handled - the quotes become part of the path
  # which would make it invalid. Users should handle quoting when passing to shell commands.
})

test_that("validate_gs_path messages about special characters", {
  # Special characters that need attention
  expect_message(
    validate_gs_path("gs://bucket/file*.txt"),
    "Path contains special characters"
  )
  expect_message(
    validate_gs_path("gs://bucket/file[1-3].txt"),
    "Path contains special characters"
  )
  expect_message(
    validate_gs_path("gs://bucket/file{a,b}.txt"),
    "Path contains special characters"
  )
  expect_message(
    validate_gs_path("gs://bucket/file!.txt"),
    "Path contains special characters"
  )
  expect_message(
    validate_gs_path("gs://bucket/file?.txt"),
    "Path contains special characters"
  )

  # Check the message contains the actual character
  expect_message(validate_gs_path("gs://bucket/file*.txt"), "\\*")
  expect_message(validate_gs_path("gs://bucket/file[1].txt"), "\\[")
})
