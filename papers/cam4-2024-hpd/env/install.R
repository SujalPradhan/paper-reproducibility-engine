# Exact versions used (R 4.6.1, macOS). Install with remotes::install_version for pinning.
pk <- c(metafor = "5.2.1", meta = "8.5.0", lme4 = "2.0.6", readxl = "1.6.0", jsonlite = "2.0.0")
if (!requireNamespace("remotes", quietly = TRUE)) install.packages("remotes", repos = "https://cloud.r-project.org")
for (p in names(pk)) remotes::install_version(p, version = pk[[p]], repos = "https://cloud.r-project.org", upgrade = "never")
