# rgsutil

An R package for seamless interaction with Google Cloud Storage. This package provides intuitive wrapper functions around the `gcloud storage` CLI commands, enabling efficient file operations with automatic caching, compression support, and pipe command integration.

## Features

- **Smart Caching**: Automatically caches downloaded files and checks for updates
- **Compression Support**: Native handling of BGZ-compressed files (common in genomics)
- **Pipe Integration**: Pre-process files with shell commands before reading
- **Type Safety**: All functions validate Google Storage paths (must start with `gs://`)
- **Progress Feedback**: Clear messages during upload/download operations

## Prerequisites

- R (>= 3.5.0)
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) installed and authenticated
- `bgzip` (for BGZ compression support, typically installed with htslib/samtools)

## Configuration

The package can be configured to handle common issues, especially on macOS with RStudio:

```r
# Show current configuration
rgsutil_config_show()

# Set custom gcloud path (common issue on macOS with RStudio)
rgsutil_configure(gcloud_path = "/usr/local/bin/gcloud")
# or for Homebrew on Apple Silicon
rgsutil_configure(gcloud_path = "/opt/homebrew/bin/gcloud")

# Set custom cache directory
# Default: /tmp/rgsutil_cache (persists across R sessions, cleaned by OS)
rgsutil_configure(cache_dir = "~/my_gcs_cache")

# Set both at once
rgsutil_configure(
  gcloud_path = "/usr/local/bin/gcloud",
  cache_dir = "~/.rgsutil_cache"
)

# These can also be set via options at startup (e.g., in .Rprofile)
options(
  rgsutil.gcloud_path = "/usr/local/bin/gcloud",
  rgsutil.cache_dir = "~/.rgsutil_cache"
)
```

## Installation

```r
remotes::install_github("mkanai/rgsutil")
```

## Quick Start

```r
library(rgsutil)

# Read a file from Google Cloud Storage
df <- read_gsfile("gs://my-bucket/data/results.csv")

# Write a data frame to Google Cloud Storage
write_gsfile(df, "gs://my-bucket/output/processed.tsv", overwrite = TRUE)

# Check if a file exists
if (gsfile_exists("gs://my-bucket/data/input.csv")) {
  message("File found!")
}

# List files in a directory
files <- list_gsfile("gs://my-bucket/data/")
```

## Main Functions

### Reading and Writing

- `read_gsfile()` - Read a single file with automatic caching and update checking
- `read_gsfiles()` - Read multiple files matching a pattern with batch optimization
- `map_dfr_gsfiles()` - Read and process multiple files, combining rows (shorthand for `read_gsfiles` with `combine="rows"`)
- `map_dfc_gsfiles()` - Read and process multiple files, combining columns (shorthand for `read_gsfiles` with `combine="cols"`)
- `write_gsfile()` - Write data frames with overwrite protection

### File Operations

- `download_gsfile()` - Download files to local directory
- `upload_gsfile()` - Upload local files to Google Cloud Storage
- `gsfile_exists()` - Check if a remote file exists
- `list_gsfile()` - List files in a bucket or directory

### Utilities

- `check_update()` - Compare timestamps between remote and cached files

## Advanced Usage

### Working with Compressed Files

```r
# Read BGZ-compressed genomics data
variants <- read_gsfile("gs://genomics-bucket/variants.tsv.bgz", sep = "\t")

# Write compressed output
write_gsfile(filtered_variants, "gs://genomics-bucket/filtered.tsv.bgz")
```

### Using Pipe Commands

```r
# Read only first 1000 lines of a large file
preview <- read_gsfile("gs://my-bucket/huge-file.csv",
                       extra_pipe_cmd = "head -n 1000")

# Filter specific columns while reading
subset <- read_gsfile("gs://my-bucket/data.tsv",
                      extra_pipe_cmd = "cut -f1,3,5")

# Search for specific patterns
matches <- read_gsfile("gs://my-bucket/logs.txt",
                       extra_pipe_cmd = "grep ERROR")
```

### Cache Management

```r
# Use custom cache directory
df <- read_gsfile("gs://my-bucket/data.csv",
                  cache.dir = "~/my-cache")

# Force re-download by using a temporary cache
df <- read_gsfile("gs://my-bucket/data.csv",
                  cache.dir = tempdir())
```

### Batch Operations

```r
# Read all files at once with batch downloading
data_list <- read_gsfiles("gs://my-bucket/data/*.csv")

# Read specific files
specific_data <- read_gsfiles(c(
  "gs://my-bucket/data/file1.csv",
  "gs://my-bucket/data/file2.csv"
))

# Use brace expansion (like bash)
monthly_data <- read_gsfiles(
  "gs://my-bucket/reports/2024-{jan,feb,mar}.csv",
  combine = "rows"
)

# Combine multiple patterns
all_data <- read_gsfiles(
  c("gs://my-bucket/2023/*.csv", 
    "gs://my-bucket/2024/*.csv"),
  combine = "rows"
)

# Process files with custom function (similar to purrr::map)
processed <- read_gsfiles(
  "gs://my-bucket/logs/2024-*.txt",
  func = function(df, path) {
    df %>%
      mutate(source = basename(path)) %>%
      filter(status == "ERROR")
  },
  combine = "rows"
)

# Or use the map_dfr_gsfiles shorthand (combines rows)
results <- map_dfr_gsfiles("gs://my-bucket/data/*.csv", function(df, path) {
  df %>% mutate(file = path)
})

# Use map_dfc_gsfiles to combine columns
combined_cols <- map_dfc_gsfiles("gs://my-bucket/metrics/{jan,feb,mar}.csv", function(df, path) {
  month <- gsub(".*/(\\w+)\\.csv", "\\1", path)
  setNames(df, paste0(names(df), "_", month))
})

# Enable parallel processing for large file sets
# install.packages(c("furrr", "future"))  # For parallel with progress bar
# install.packages("purrr")               # For sequential with progress bar
big_data <- read_gsfiles(
  "gs://my-bucket/large-dataset/*.parquet",
  parallel = TRUE,  # Use all cores
  combine = "rows",
  .progress = TRUE  # Show progress bar
)
```

## License

MIT License

## Author

Masahiro Kanai (mkanai@broadinstitute.org)
