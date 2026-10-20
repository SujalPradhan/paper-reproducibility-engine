# Exact package versions used for the reproduction of ee-2021-salmon-smr (R 4.6.1, macOS arm64).
# Installs into env/Rlib (paper-local). Requires the 'remotes' package or uses CRAN archive URLs.
lib <- "env/Rlib"; dir.create(lib, showWarnings = FALSE, recursive = TRUE)
options(repos = c(CRAN = "https://cloud.r-project.org"))
pk <- c(tidyverse = "2.0.0", mclust = "6.1.3", lmerTest = "3.2.1", MuMIn = "1.48.19",
        cvms = "2.0.1", sjPlot = "2.9.0", ggeffects = "2.3.2", janitor = "2.2.1",
        multidplyr = "0.1.4", lme4 = "2.0-6", car = "3.1-5", readxl = "1.6.0",
        dplyr = "1.2.1", ggplot2 = "4.0.3", jsonlite = "2.0.0")
if (!requireNamespace("remotes", quietly = TRUE)) install.packages("remotes", lib = lib)
for (p in names(pk)) {
  have <- tryCatch(as.character(packageVersion(p)), error = function(e) "")
  if (have != pk[[p]]) remotes::install_version(p, version = pk[[p]], lib = lib, upgrade = "never")
}
# Sensitivity only: mclust version used by the authors
dir.create("env/Rlib_mclust547", showWarnings = FALSE)
install.packages("https://cran.r-project.org/src/contrib/Archive/mclust/mclust_5.4.7.tar.gz",
                 repos = NULL, type = "source", lib = "env/Rlib_mclust547")
