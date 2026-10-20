# Environment used: R 4.6.1 (macOS, Homebrew). Exact versions:
#   haven 2.5.5 (deps: forcats 1.0.1, readr 2.2.0, vroom 1.7.1, tzdb 0.5.0, bit 4.6.0, bit64 4.8.6, clipr 0.8.1)
#   jsonlite 2.0.0
# Installs into the project-local library env/rlib, which code/reproduce.R adds to .libPaths().
# Run from the paper folder: Rscript env/install.R
lib <- file.path("env", "rlib"); dir.create(lib, showWarnings = FALSE, recursive = TRUE)
if (!requireNamespace("remotes", quietly = TRUE))
  install.packages("remotes", repos = "https://cloud.r-project.org", lib = lib)
.libPaths(c(lib, .libPaths()))
pk <- c(haven = "2.5.5", jsonlite = "2.0.0")
for (p in names(pk))
  remotes::install_version(p, version = pk[[p]], repos = "https://cloud.r-project.org",
                           lib = lib, upgrade = "never")
