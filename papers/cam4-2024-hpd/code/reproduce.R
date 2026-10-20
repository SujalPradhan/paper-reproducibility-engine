# Reproduction of Kim et al. (2024) Cancer Medicine, doi:10.1002/cam4.6970
# HPD incidence meta-analysis: GLMM (logit, ML) + multivariable meta-regression.
# Usage: Rscript code/reproduce.R [data_dir]
# Writes outputs/results.json, outputs/model_output.txt, outputs/sensitivity.json
t0 <- Sys.time()
suppressPackageStartupMessages({
  library(readxl); library(metafor); library(meta); library(jsonlite)
})

args <- commandArgs(trailingOnly = TRUE)
script_dir <- tryCatch({
  f <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))
  dirname(normalizePath(f))
}, error = function(e) getwd())
if (length(script_dir) == 0) script_dir <- getwd()
data_dir <- if (length(args) >= 1) args[1] else file.path(script_dir, "..", "data")
out_dir  <- file.path(script_dir, "..", "outputs")
dir.create(out_dir, showWarnings = FALSE)

# ---- Step 1: load sheet 1, all 34 studies --------------------------------
d <- as.data.frame(read_excel(file.path(data_dir, "updated_extracted_data_HPD_22.08.29.xlsx"),
                              sheet = "meta_data_22.02.14_analysis"))
d$hpd <- as.numeric(d$hpd); d$total <- as.numeric(d$total)
stopifnot(nrow(d) == 34, sum(d$hpd) == 558, sum(d$total) == 4117)
d$histology  <- relevel(factor(d$histology), ref = "RCC")
d$definition <- relevel(factor(d$definition), ref = "C")

sink(file.path(out_dir, "model_output.txt"))
cat("Data (sheet 1):\n"); print(d)
cat("\nTotals: events =", sum(d$hpd), " patients =", sum(d$total), "\n")

# ---- Step 2: pooled incidence GLMM (C1, C2) ------------------------------
m0 <- rma.glmm(measure = "PLO", xi = hpd, ni = total, data = d, method = "ML", test = "t")
cat("\n==== Pooled GLMM: rma.glmm(PLO, ML, test='t') ====\n"); print(m0)
pr0 <- predict(m0, transf = transf.ilogit)
cat("\nBack-transformed pooled incidence (proportion), CI and PI:\n"); print(pr0)

# meta wrapper for cross-check (also gives I2 and IV Q)
mp <- metaprop(event = hpd, n = total, studlab = study, data = d, sm = "PLOGIT",
               method = "GLMM", method.tau = "ML", method.random.ci = "HK",
               method.predict = "HTS")
cat("\n==== meta::metaprop (GLMM, ML, HK) ====\n"); print(summary(mp))

# ---- Step 4: subgroups (context) ----------------------------------------
cat("\n==== Subgroup GLMMs ====\n")
for (v in c("definition", "histology")) for (lv in levels(d[[v]])) {
  s <- d[d[[v]] == lv, ]
  f <- tryCatch(rma.glmm(measure = "PLO", xi = hpd, ni = total, data = s, method = "ML", test = "t"),
                error = function(e) NULL)
  if (is.null(f)) { cat(v, "=", lv, ": fit failed\n"); next }
  p <- predict(f, transf = transf.ilogit)
  cat(sprintf("%s = %-15s k=%2d  incidence %.1f%% (%.1f-%.1f)\n", v, lv, nrow(s),
              100 * p$pred, 100 * p$ci.lb, 100 * p$ci.ub))
}
u_def  <- rma.glmm(measure = "PLO", xi = hpd, ni = total, mods = ~ definition, data = d, method = "ML", test = "t")
u_hist <- rma.glmm(measure = "PLO", xi = hpd, ni = total, mods = ~ histology,  data = d, method = "ML", test = "t")
cat("\nUnivariable omnibus p: definition =", signif(u_def$QMp, 3), " histology =", signif(u_hist$QMp, 3), "\n")

# ---- Step 5: multivariable meta-regression (C3-C6) -----------------------
m1 <- rma.glmm(measure = "PLO", xi = hpd, ni = total, mods = ~ histology + definition,
               data = d, method = "ML", test = "t")
cat("\n==== Multivariable meta-regression: rma.glmm(PLO, ML, test='t') ====\n"); print(m1)
or_tab <- data.frame(term = rownames(m1$beta), OR = exp(m1$beta[, 1]),
                     ci.lb = exp(m1$ci.lb), ci.ub = exp(m1$ci.ub), p = m1$pval)
cat("\nAdjusted odds ratios (exp(coef)):\n"); print(or_tab, digits = 4)
sink()

# ---- Sensitivity (not graded) -------------------------------------------
m0z <- rma.glmm(measure = "PLO", xi = hpd, ni = total, data = d, method = "ML", test = "z")
m1z <- rma.glmm(measure = "PLO", xi = hpd, ni = total, mods = ~ histology + definition,
                data = d, method = "ML", test = "z")
sens <- list(
  note = "Sensitivity analyses, clearly labelled; not used for claims.",
  C1_z_test_percent = with(predict(m0z, transf = transf.ilogit), 100 * c(pred = pred, ci.lb = ci.lb, ci.ub = ci.ub)),
  C2_Q_LRT = list(Q = m0$QE.LRT, p = m0$QEp.LRT),
  C2_Q_meta_metaprop = list(Q = as.list(mp$Q), p = as.list(mp$pval.Q)),
  I2_metafor = m0$I2, I2_meta = 100 * mp$I2,
  metareg_z_test = setNames(lapply(seq_len(nrow(m1z$beta)), function(i)
    list(OR = exp(m1z$beta[i, 1]), ci = exp(c(m1z$ci.lb[i], m1z$ci.ub[i])), p = m1z$pval[i])),
    rownames(m1z$beta))
)
write_json(sens, file.path(out_dir, "sensitivity.json"), auto_unbox = TRUE, digits = 8, pretty = TRUE)

# ---- results.json --------------------------------------------------------
getOR <- function(term, id, label) {
  i <- which(rownames(m1$beta) == term)
  list(id = id, status = "ok", value = unname(exp(m1$beta[i, 1])), p = unname(m1$pval[i]),
       ci = unname(exp(c(m1$ci.lb[i], m1$ci.ub[i]))),
       notes = sprintf("Adjusted OR %s from rma.glmm(PLO, ML, test='t', mods=~histology+definition; ref RCC, C); t-based 95%% CI %.2f-%.2f, df=%d.",
                       label, exp(m1$ci.lb[i]), exp(m1$ci.ub[i]), m1$dfs))
}
claims <- list(
  list(id = "C1", status = "ok", value = 100 * unname(pr0$pred), p = NULL,
       ci = 100 * unname(c(pr0$ci.lb, pr0$ci.ub)),
       notes = sprintf("Pooled incidence %% from rma.glmm(PLO, ML, test='t'), back-transformed; t-based 95%% CI %.1f-%.1f%%, 95%% PI %.1f-%.1f%%, I2=%.1f%%, k=%d, events/N=%d/%d.",
                       100 * pr0$ci.lb, 100 * pr0$ci.ub, 100 * pr0$pi.lb, 100 * pr0$pi.ub, m0$I2,
                       m0$k, sum(d$hpd), sum(d$total))),
  list(id = "C2", status = "ok", value = unname(m0$QE.Wld), p = unname(m0$QEp.Wld),
       notes = sprintf("Wald-type heterogeneity Q (QE.Wld) from rma.glmm, df=%d. LRT Q=%.2f (sensitivity.json). meta::metaprop Wald Q=%.2f; meta I2=%.1f%% (metafor I2=%.1f%%).",
                       m0$k - 1, m0$QE.LRT, mp$Q[["Wald"]], 100 * mp$I2, m0$I2)),
  getOR("histologyAGC", "C3", "AGC vs RCC"),
  getOR("histologyHCC", "C4", "HCC vs RCC"),
  getOR("histologyNSCLC", "C5", "NSCLC vs RCC"),
  getOR("definitionB", "C6", "definition B vs C")
)
claims[[1]]$p <- NULL
pk <- c("metafor", "meta", "lme4", "readxl", "jsonlite")
software <- c(list(R = paste(R.version$major, R.version$minor, sep = ".")),
              setNames(lapply(pk, function(p) as.character(packageVersion(p))), pk))
res <- list(paper_id = "cam4-2024-hpd",
            run = list(script = "code/reproduce.R", used_author_code = FALSE,
                       runtime_s = round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 1),
                       software = software, seed = NULL),
            claims = claims)
write_json(res, file.path(out_dir, "results.json"), auto_unbox = TRUE, digits = 8,
           pretty = TRUE, null = "null")
cat("Wrote", file.path(out_dir, "results.json"), "\n")
