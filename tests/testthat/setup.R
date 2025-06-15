# Helper function to skip tests if offline
skip_if_offline <- function() {
  # Simple check - try to resolve a known domain
  tryCatch(
    {
      suppressWarnings(readLines("https://www.google.com", n = 1))
      TRUE
    },
    error = function(e) {
      skip("No internet connection")
    }
  )
}
