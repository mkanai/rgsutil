test_that("get_gcloud_cmd finds gcloud", {
  # Should find gcloud (either in PATH or common locations)
  expect_no_error({
    cmd <- get_gcloud_cmd()
  })

  # Should return a string
  cmd <- get_gcloud_cmd()
  expect_true(is.character(cmd))
  expect_true(nzchar(cmd))
})

test_that("get_gcloud_cmd respects custom path option", {
  # Set a custom path
  old_option <- getOption("rgsutil.gcloud_path")
  options(rgsutil.gcloud_path = "/custom/path/to/gcloud")

  expect_equal(get_gcloud_cmd(), "/custom/path/to/gcloud")

  # Restore original option
  options(rgsutil.gcloud_path = old_option)
})

test_that("get_cache_dir returns valid directory", {
  # Should return a directory path
  cache_dir <- get_cache_dir()
  expect_true(is.character(cache_dir))
  expect_true(nzchar(cache_dir))

  # Directory should exist after calling the function
  expect_true(dir.exists(cache_dir))
})

test_that("get_cache_dir respects custom cache option", {
  # Set a custom cache directory
  old_option <- getOption("rgsutil.cache_dir")
  test_cache_dir <- file.path(tempdir(), "rgsutil_test_cache")
  options(rgsutil.cache_dir = test_cache_dir)

  cache_dir <- get_cache_dir()
  expect_equal(cache_dir, test_cache_dir)
  expect_true(dir.exists(cache_dir))

  # Clean up
  unlink(test_cache_dir, recursive = TRUE)
  options(rgsutil.cache_dir = old_option)
})

test_that("rgsutil_configure sets options correctly", {
  # Save original options
  old_gcloud <- getOption("rgsutil.gcloud_path")
  old_cache <- getOption("rgsutil.cache_dir")

  # Test setting gcloud path - expect both message and warning
  suppressWarnings({
    expect_message(
      {
        rgsutil_configure(gcloud_path = "/test/path/gcloud")
      },
      "Set gcloud path to"
    )
  })
  expect_equal(getOption("rgsutil.gcloud_path"), "/test/path/gcloud")

  # Test setting cache directory
  test_cache <- file.path(tempdir(), "test_configure_cache")
  expect_message(
    {
      rgsutil_configure(cache_dir = test_cache)
    },
    "Set cache directory to"
  )
  expect_equal(getOption("rgsutil.cache_dir"), test_cache)
  expect_true(dir.exists(test_cache))

  # Test setting both - expect both message and warning
  suppressWarnings({
    expect_message(
      {
        rgsutil_configure(
          gcloud_path = "/another/path/gcloud",
          cache_dir = file.path(tempdir(), "another_cache")
        )
      },
      "Set gcloud path to"
    )
  })

  # Clean up
  unlink(test_cache, recursive = TRUE)
  unlink(file.path(tempdir(), "another_cache"), recursive = TRUE)
  options(rgsutil.gcloud_path = old_gcloud)
  options(rgsutil.cache_dir = old_cache)
})

test_that("rgsutil_configure warns about non-existent gcloud path", {
  old_gcloud <- getOption("rgsutil.gcloud_path")

  expect_warning(
    {
      rgsutil_configure(gcloud_path = "/this/does/not/exist/gcloud")
    },
    "gcloud path does not exist"
  )

  # Restore
  options(rgsutil.gcloud_path = old_gcloud)
})

test_that("rgsutil_config_show displays configuration", {
  expect_output(
    {
      rgsutil_config_show()
    },
    "rgsutil configuration:"
  )

  expect_output(
    {
      rgsutil_config_show()
    },
    "gcloud path:"
  )

  expect_output(
    {
      rgsutil_config_show()
    },
    "cache directory:"
  )
})
