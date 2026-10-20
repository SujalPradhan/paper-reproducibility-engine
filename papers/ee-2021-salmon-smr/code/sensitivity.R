# sensitivity.R -- NOT graded. Labelled alternatives written to outputs/sensitivity.json.
# S1: author prep (1-prep-functions, 2-prep-data) + mod_rate1 / mod_condition1 with mclust 5.4.7
#     (the paper's version) instead of CRAN-current mclust.
# Usage: Rscript code/sensitivity.R
args <- commandArgs(trailingOnly = FALSE)
f <- sub("^--file=", "", args[grep("^--file=", args)])
root <- if (length(f)) normalizePath(file.path(dirname(f), "..")) else normalizePath(".")
.libPaths(c(file.path(root, "env", "Rlib_mclust547"), file.path(root, "env", "Rlib"), .libPaths()))
stopifnot(as.character(packageVersion("mclust")) == "5.4.7")
code_dir <- file.path(root, "code", "author_run"); out_dir <- file.path(root, "outputs")

owd <- setwd(file.path(root, "data"))
invisible(capture.output({
  source(file.path(code_dir, "script-Ash2021-1-prep-functions.R"), local = globalenv())
  source(file.path(code_dir, "script-Ash2021-2-prep-data.R"), local = globalenv())
}))
setwd(owd)
mod_rate1 <- lmerTest::lmer(log10(SMR) ~ log10(weight) + geno_vgll3*sex + avgTemp + (1|family)+(1|batch),
                            data = tb_smr)
mod_condition1 <- lmerTest::lmer(condition ~ geno_vgll3*sex + (1|batch) + (1|family), data = tb_smr)
capture.output({print(summary(mod_rate1)); print(confint(mod_rate1)); print(anova(mod_rate1, type = 3))},
               file = file.path(out_dir, "sensitivity_S1_mclust547_model1.txt"))
sm <- summary(mod_rate1)$coefficients; ci <- suppressMessages(confint(mod_rate1)); av <- anova(mod_rate1, type = 3)
smc <- summary(mod_condition1)$coefficients; avc <- anova(mod_condition1, type = 3)

# compare SMR per fish with the main run (CRAN mclust)
main <- tryCatch(read.csv(file.path(out_dir, "tb_smr.csv")), error = function(e) NULL)
cmp <- NULL
if (!is.null(main)) {
  m <- merge(main[, c("ID_fish", "SMR")], data.frame(ID_fish = tb_smr$ID_fish, SMR547 = tb_smr$SMR))
  cmp <- list(n_fish = nrow(m), n_differ_1e8 = sum(abs(m$SMR - m$SMR547) > 1e-8),
              max_abs_diff = max(abs(m$SMR - m$SMR547)))
}
s1 <- list(
  label = "S1: mclust 5.4.7 (paper version) instead of mclust 6.1.3; everything else identical",
  mclust = as.character(packageVersion("mclust")), N = nobs(mod_rate1),
  smr_vs_main = cmp,
  C1 = list(value = sm["log10(weight)", "Estimate"], ci = unname(ci["log10(weight)", ]),
            p = av["log10(weight)", "Pr(>F)"], F = av["log10(weight)", "F value"]),
  C2 = list(value = sm["geno_vgll3LL", "Estimate"], ci = unname(ci["geno_vgll3LL", ]),
            p = av["geno_vgll3", "Pr(>F)"], F = av["geno_vgll3", "F value"]),
  C3 = list(value = sm["geno_vgll3LL:sexmale", "Estimate"], ci = unname(ci["geno_vgll3LL:sexmale", ]),
            p = av["geno_vgll3:sex", "Pr(>F)"], F = av["geno_vgll3:sex", "F value"],
            t_p = sm["geno_vgll3LL:sexmale", "Pr(>|t|)"]),
  C4 = list(value = sigma(mod_rate1)),
  C5 = list(value = smc["geno_vgll3LL", "Estimate"], p = avc["geno_vgll3", "Pr(>F)"])
)
sens_file <- file.path(out_dir, "sensitivity.json")
old <- if (file.exists(sens_file)) jsonlite::read_json(sens_file) else list()
old[["S1_mclust_5.4.7"]] <- s1
jsonlite::write_json(old, sens_file, auto_unbox = TRUE, pretty = TRUE, digits = NA)
str(s1)
