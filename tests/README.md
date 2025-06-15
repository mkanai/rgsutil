# rgsutil Test Suite

This directory contains comprehensive tests for the rgsutil package using the testthat framework.

## Test Files

- **test-validate_gs_path.R**: Tests for the GS path validation function
  - Validates correct paths (single and multiple)
  - Rejects invalid paths (missing prefix, empty, NA)
  - Detects forbidden characters
  - Warns about spaces
  - Messages about special characters

- **test-read_write.R**: Tests for reading and writing GS files
  - Uses real data from `gs://gcp-public-data--gnomad/`
  - Tests caching behavior
  - Tests path validation
  - Includes placeholder tests for write operations (requires mockery)

- **test-file_management.R**: Tests for file management operations
  - list_gsfile with public data
  - gsfile_exists functionality
  - check_update for timestamp comparison
  - download_gsfile with directory creation
  - upload_gsfile validation

- **test-utils.R**: Tests for utility functions
  - gcloud command discovery
  - Cache directory management
  - Configuration options
  - Configuration display

- **test-wrappers.R**: Tests for fread/fwrite wrapper functions
  - Regular file handling
  - Compressed file support
  - Pipe command support
  - Directory creation

## Running Tests

```r
# Run all tests
testthat::test_local()

# Run specific test file
testthat::test_file("tests/testthat/test-validate_gs_path.R")
```

## Test Data

Tests use publicly available data from gnomAD:
- `gs://gcp-public-data--gnomad/release/4.1/tsv/exomes/`

This ensures tests can run without authentication while testing real GCS functionality.

## Notes

- Tests requiring internet connection are skipped when offline
- Write operations are tested with mocks to avoid actual uploads
- The test suite validates the new path validation functionality thoroughly