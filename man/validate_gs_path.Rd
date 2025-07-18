% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utils.R
\name{validate_gs_path}
\alias{validate_gs_path}
\title{Validate Google Storage path}
\usage{
validate_gs_path(path, allow_multiple = FALSE)
}
\arguments{
\item{path}{Character string. The Google Storage path to validate.}

\item{allow_multiple}{Logical. Whether to allow multiple paths (default FALSE).}
}
\value{
TRUE if valid, otherwise throws an error with descriptive message.
}
\description{
Checks if a Google Storage path is valid. A valid path must:
- Start with "gs://"
- Not contain spaces or special characters unless properly quoted
}
\details{
This function validates Google Storage paths to catch common errors early.
It checks for:
- Correct "gs://" prefix
- Unquoted spaces (spaces are allowed if the entire path is quoted)
- Special characters that may cause issues with shell commands

Special characters that are always forbidden: < > | & ; ` $ \\ newline
Characters that require quoting: space, !, ?, *, [, ], \{, \}, (, ), ', "
}
\keyword{internal}
