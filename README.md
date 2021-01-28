# rgsutil

A simple wrapper for `gsutil` in R. Internally, it invokes `system` to call `gsutil`.

## Installation
```
devtools::install_github("mkanai/rgsutil")
```

## Usage
```
df = rgsutil::read_gsfile("gs://bucket/path/to/file")

rgsutil::write_gsfile(df, "gs://bucket/path/to/file", overwrite = FALSE)
```
