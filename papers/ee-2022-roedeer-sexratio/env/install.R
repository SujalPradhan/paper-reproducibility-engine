# Exact versions used for the reproduction run (R 4.6.1, CRAN).
install.packages("remotes", repos = "https://cloud.r-project.org")
remotes::install_version("metafor", version = "5.2.1", repos = "https://cloud.r-project.org")
remotes::install_version("jsonlite", version = "2.0.0", repos = "https://cloud.r-project.org")
# metafor dependencies resolved by CRAN at install time (metadat, numDeriv, pbapply, mathjaxr, digest, Matrix, nlme).
