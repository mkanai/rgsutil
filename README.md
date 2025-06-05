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

## Installation

```r
# Install from GitHub
devtools::install_github("mkanai/rgsutil")

# Or using remotes
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

- `read_gsfile()` - Read files with automatic caching and update checking
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
# List and process multiple files
csv_files <- list_gsfile("gs://my-bucket/data/*.csv")

results <- lapply(csv_files, function(file) {
  df <- read_gsfile(file)
  # Process each file
  return(summary(df))
})
```

## Performance Tips

1. **Use caching**: The default cache directory (`/tmp`) works well for most use cases
2. **Leverage pipe commands**: Pre-filter large files to reduce memory usage
3. **BGZ compression**: Use for large genomics data files to save storage and bandwidth
4. **Batch operations**: Use `list_gsfile()` with `lapply()` for processing multiple files

## License

MIT License

## Author

Masahiro Kanai (<mkanai@broadinstitute.org>)
