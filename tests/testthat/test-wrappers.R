test_that("fread_wrapper handles regular files", {
  # Create a test CSV file
  test_file <- tempfile(fileext = ".csv")
  test_data <- data.frame(
    x = 1:5,
    y = letters[1:5],
    stringsAsFactors = FALSE
  )
  write.csv(test_data, test_file, row.names = FALSE)

  # Read it back
  df <- fread_wrapper(test_file)
  expect_equal(nrow(df), 5)
  expect_equal(ncol(df), 2)
  expect_equal(df$x, 1:5)

  # Clean up
  unlink(test_file)
})

test_that("fread_wrapper handles compressed files", {
  # Create a test compressed file
  test_file <- tempfile(fileext = ".csv.gz")
  test_data <- data.frame(
    x = 1:3,
    y = c("a", "b", "c"),
    stringsAsFactors = FALSE
  )

  # Write compressed
  gz_con <- gzfile(test_file, "w")
  write.csv(test_data, gz_con, row.names = FALSE)
  close(gz_con)

  # Read it back
  df <- fread_wrapper(test_file)
  expect_equal(nrow(df), 3)
  expect_equal(df$x, 1:3)

  # Clean up
  unlink(test_file)
})

test_that("fread_wrapper handles pipe commands", {
  # Create a test file with multiple lines
  test_file <- tempfile(fileext = ".txt")
  writeLines(c(
    "header1\theader2",
    "1\ta",
    "2\tb",
    "3\tc",
    "4\td",
    "5\te"
  ), test_file)

  # Read with head command
  df <- fread_wrapper(test_file, extra_pipe_cmd = "head -n 3")
  expect_equal(nrow(df), 2) # header + 2 data rows

  # Read with grep command
  df <- fread_wrapper(test_file, extra_pipe_cmd = "grep -E '[a-c]$'")
  expect_equal(nrow(df), 3) # rows ending with a, b, or c

  # Clean up
  unlink(test_file)
})

test_that("fwrite_wrapper handles regular files", {
  test_data <- data.frame(
    x = 1:3,
    y = c("a", "b", "c"),
    stringsAsFactors = FALSE
  )

  # Write to file
  test_file <- tempfile(fileext = ".tsv")
  fwrite_wrapper(test_data, test_file, sep = "\t")

  # Check file exists and read it back
  expect_true(file.exists(test_file))
  df <- data.table::fread(test_file)
  expect_equal(nrow(df), 3)
  expect_equal(df$x, 1:3)

  # Clean up
  unlink(test_file)
})

test_that("fwrite_wrapper creates directories if needed", {
  test_data <- data.frame(x = 1:2)

  # Create a path with non-existent directory
  test_dir <- file.path(tempdir(), "fwrite_test_dir", "nested")
  test_file <- file.path(test_dir, "output.csv")

  # Should create directory and write file
  expect_no_error({
    fwrite_wrapper(test_data, test_file)
  })

  expect_true(dir.exists(test_dir))
  expect_true(file.exists(test_file))

  # Clean up
  unlink(dirname(test_dir), recursive = TRUE)
})
