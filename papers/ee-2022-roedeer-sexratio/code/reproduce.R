#!/usr/bin/env Rscript
# Reproduction of Hagen et al. (2022) Ecology and Evolution, doi:10.1002/ece3.8938
# Claims C1-C6 from claims.json. No author code available.
# Usage: Rscript code/reproduce.R [path/to/data]   (default: ../data relative to this script)

t0 <- Sys.time()
suppressPackageStartupMessages({
  library(metafor)
  library(jsonlite)
})

args_all <- commandArgs(trailingOnly = FALSE)
script_file <- sub("^--file=", "", args_all[grep("^--file=", args_all)])
script_dir <- if (length(script_file)) dirname(normalizePath(script_file)) else getwd()
args <- commandArgs(trailingOnly = TRUE)
data_dir <- if (length(args) >= 1) normalizePath(args[1]) else normalizePath(file.path(script_dir, "..", "data"))
paper_dir <- normalizePath(file.path(script_dir, ".."))
out_dir <- file.path(paper_dir, "outputs")
dir.create(out_dir, showWarnings = FALSE)

# ---- 0. checksums ------------------------------------------------------------
expected_sha <- c(
  "Sex_BW.csv" = "fcacfc6a2cd9688593e0a0ac62e167fc5369286c55118856dbabebb6c5667179",
  "Metafor_roe_sex.csv" = "6420d015eae45e34904639edd2f571998279727a744a2532ea8d825a94d4fa77",
  "Temp_Data_comma_sep.csv" = "5f32728a4cbea2e164b4930d9b43446fac581cefbdc943c1fb7e35a783f072ab")
sha_ok <- sapply(names(expected_sha), function(f) {
  s <- tryCatch(system2("shasum", c("-a", "256", shQuote(file.path(data_dir, f))), stdout = TRUE),
                error = function(e) NA_character_)
  identical(sub(" .*", "", s), unname(expected_sha[f]))
})
if (!all(sha_ok)) warning("Checksum mismatch: ", paste(names(sha_ok)[!sha_ok], collapse = ", "))

out_txt <- file.path(out_dir, "model_output.txt")
sink(out_txt)
cat("Reproduction of ee-2022-roedeer-sexratio\nRun at", format(Sys.time(), tz = "UTC", usetz = TRUE), "\n")
cat("Checksums OK:", paste(names(sha_ok), sha_ok, collapse = "; "), "\n\n")

# ---- 1. Sex_BW: C1, C2 -------------------------------------------------------
sex <- read.csv(file.path(data_dir, "Sex_BW.csv"), sep = ";", na.strings = "NA",
                stringsAsFactors = FALSE)
cat("Sex_BW.csv rows:", nrow(sex), " years", range(sex$Year), "\n")
cat("Sex table (raw, incl NA):\n"); print(table(sex$Sex, useNA = "always"))

d1 <- subset(sex, !is.na(Sex) & Sex %in% c("f", "m") & Year >= 1972 & Year <= 2019)
N <- nrow(d1)
N_hasl <- sum(!is.na(d1$Hasl))
n_f <- sum(d1$Sex == "f")
cat("\nAfter dropping Sex NA and Year outside 1972-2019: N =", N, "\n")
cat("  of which with non-NA Hasl:", N_hasl, "\n")
cat("  n female =", n_f, "\n")
bt <- binom.test(n_f, N, p = 0.5)
print(bt)
bt_h <- binom.test(sum(d1$Sex[!is.na(d1$Hasl)] == "f"), N_hasl, p = 0.5)
cat("Sensitivity (Hasl-NA rows dropped): pf =", unname(bt_h$estimate),
    "CI", bt_h$conf.int, "\n")

# ---- 2. Climate covariates and GLM: C5, C6 ----------------------------------
clim <- read.csv(file.path(data_dir, "Temp_Data_comma_sep.csv"), sep = ";", dec = ",")
prev <- clim[match(d1$Year - 1, clim$Jahr), ]
curr <- clim[match(d1$Year, clim$Jahr), ]
d1$T_OctFeb <- (prev$Temp_BW_Oct + prev$Temp_BW_Nov + prev$Temp_BW_Dec +
                curr$Temp_BW_Jan + curr$Temp_BW_Feb) / 5
d1$P_Sep <- prev$NDS_BW_Sep
d1$T_cor <- d1$T_OctFeb - 0.65 * d1$Hasl / 100
d1$y <- as.integer(d1$Sex == "f")
gd <- subset(d1, !is.na(T_cor) & !is.na(P_Sep))
cat("\nGLM data: n =", nrow(gd), "\n")
cat("T_cor summary:\n"); print(summary(gd$T_cor))
fit <- glm(y ~ P_Sep + I(P_Sep^2) + T_cor + I(T_cor^2), family = binomial(link = "logit"), data = gd)
cat("\n== Main GLM (Equation 2, lapse-rate corrected temperature) ==\n")
print(summary(fit))
co <- coef(summary(fit))

fit_unc <- glm(y ~ P_Sep + I(P_Sep^2) + T_OctFeb + I(T_OctFeb^2), family = binomial, data = gd)
cat("\n== Sensitivity GLM: uncorrected T_OctFeb (same rows) ==\n")
print(summary(fit_unc))
co_unc <- coef(summary(fit_unc))

# ---- 3. Meta-analysis: C3, C4 ------------------------------------------------
meta <- read.csv(file.path(data_dir, "Metafor_roe_sex.csv"), sep = ";", dec = ",",
                 fileEncoding = "latin1", check.names = FALSE, stringsAsFactors = FALSE)
names(meta)[names(meta) == "Sex ratio"] <- "SexRatio"
cat("\nMetafor_roe_sex.csv rows:", nrow(meta), "\n"); print(table(meta$SexRatio))
meta$d_check <- log(meta$`Proportion females` / (1 - meta$`Proportion females`)) / (pi / sqrt(3))
cat("Max |d - d recomputed from Proportion females|:", max(abs(meta$d - meta$d_check)), "\n")

re_P <- rma(yi = d, sei = d_se, data = subset(meta, SexRatio == "P"), method = "REML")
re_S <- rma(yi = d, sei = d_se, data = subset(meta, SexRatio == "S"), method = "REML")
cat("\n== Random-effects (REML), prenatal (P) ==\n"); print(re_P)
cat("\n== Random-effects (REML), secondary (S) ==\n"); print(re_S)
sink()

# ---- 4. results.json ---------------------------------------------------------
r <- function(x, k = 6) round(unname(x), k)
claims <- list(
  list(id = "C1", status = "ok", value = N,
       notes = sprintf("Rows with Sex in {f,m} and Year 1972-2019 (stated exclusions only). Hasl-NA rows kept; N excluding Hasl-NA = %d. Raw file rows = %d.", N_hasl, nrow(sex))),
  list(id = "C2", status = "ok", value = r(bt$estimate), p = signif(bt$p.value, 4),
       ci = r(bt$conf.int),
       notes = sprintf("pf = %d/%d; exact Clopper-Pearson 95%% CI [%.4f, %.4f] (binom.test); p vs 0.5. Without Hasl-NA rows: pf = %.4f [%.4f, %.4f], n = %d.",
                       n_f, N, bt$conf.int[1], bt$conf.int[2], bt_h$estimate, bt_h$conf.int[1], bt_h$conf.int[2], N_hasl)),
  list(id = "C3", status = "ok", value = r(re_P$b[1]), p = signif(re_P$pval, 4),
       ci = r(c(re_P$ci.lb, re_P$ci.ub)), se = r(re_P$se),
       notes = sprintf("metafor rma REML on %d prenatal rows (paper says 36); tau2 = %.5f, I2 = %.2f%%.", re_P$k, re_P$tau2, re_P$I2)),
  list(id = "C4", status = "ok", value = r(re_S$b[1]), p = signif(re_S$pval, 4),
       ci = r(c(re_S$ci.lb, re_S$ci.ub)), se = r(re_S$se),
       notes = sprintf("metafor rma REML on %d secondary rows; tau2 = %.5f, I2 = %.2f%%.", re_S$k, re_S$tau2, re_S$I2)),
  list(id = "C5", status = "ok", value = r(co["T_cor", "Estimate"]), p = signif(co["T_cor", "Pr(>|z|)"], 4),
       se = r(co["T_cor", "Std. Error"]),
       notes = sprintf("glm binomial logit, n = %d (Hasl-NA dropped); T_cor = mean(Oct-Dec t-1, Jan-Feb t) - 0.65*Hasl/100; P_Sep raw mm. Uncorrected-T sensitivity: %.4f (SE %.4f, p %.3g).",
                       nrow(gd), co_unc["T_OctFeb", 1], co_unc["T_OctFeb", 2], co_unc["T_OctFeb", 4])),
  list(id = "C6", status = "ok", value = r(co["I(T_cor^2)", "Estimate"]), p = signif(co["I(T_cor^2)", "Pr(>|z|)"], 4),
       se = r(co["I(T_cor^2)", "Std. Error"]),
       notes = sprintf("Quadratic T_cor term, same model as C5. Uncorrected-T sensitivity: %.5f (SE %.5f, p %.3g).",
                       co_unc["I(T_OctFeb^2)", 1], co_unc["I(T_OctFeb^2)", 2], co_unc["I(T_OctFeb^2)", 4]))
)

sens <- list(
  note = "Sensitivity analyses, not graded.",
  C1_C2_without_Hasl_NA = list(n = N_hasl, pf = r(bt_h$estimate), ci = r(bt_h$conf.int)),
  GLM_uncorrected_temperature = lapply(as.data.frame(t(co_unc)), function(x) r(x)),
  GLM_main_all_terms = lapply(as.data.frame(t(co)), function(x) r(x))
)
write_json(sens, file.path(out_dir, "sensitivity.json"), auto_unbox = TRUE, pretty = TRUE, digits = NA)

pkgs <- c("metafor", "jsonlite", "stats")
software <- c(list(R = paste(R.version$major, R.version$minor, sep = ".")),
              setNames(lapply(pkgs, function(p) as.character(packageVersion(p))), pkgs))
res <- list(
  paper_id = "ee-2022-roedeer-sexratio",
  run = list(script = "code/reproduce.R", used_author_code = FALSE,
             runtime_s = round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 2),
             software = software, seed = NULL, checksums_ok = all(sha_ok)),
  claims = claims)
write_json(res, file.path(out_dir, "results.json"), auto_unbox = TRUE, pretty = TRUE, digits = NA, null = "null")
cat("Wrote", file.path(out_dir, "results.json"), "\n")
