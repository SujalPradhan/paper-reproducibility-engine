# reproduce.R -- ee-2021-salmon-smr (Asheim et al. 2021, Ecology and Evolution)
# Runs the authors' pipeline (code/author_run/, minimally edited copies of code/author/;
# see steps.log for every edit), extracts claim values C1-C6 and writes outputs/results.json.
# Usage (from anywhere): Rscript code/reproduce.R
t_start <- Sys.time()

# ---- locate paper root -------------------------------------------------------
args <- commandArgs(trailingOnly = FALSE)
f <- sub("^--file=", "", args[grep("^--file=", args)])
root <- if (length(f)) normalizePath(file.path(dirname(f), "..")) else normalizePath(".")
lib_local <- file.path(root, "env", "Rlib")
if (dir.exists(lib_local)) .libPaths(c(lib_local, .libPaths()))

out_dir  <- file.path(root, "outputs")
data_dir <- file.path(root, "data")
code_dir <- file.path(root, "code", "author_run")
dir.create(out_dir, showWarnings = FALSE)

SEED <- 1  # used only for the (originally unseeded) power analysis, C6

# ---- run the author pipeline -------------------------------------------------
pdf(file.path(out_dir, "author_diagnostic_plots.pdf"))   # sink for sjPlot/qqnorm/plot calls
log_con <- file(file.path(out_dir, "author_run_output.txt"), open = "wt")
sink(log_con); sink(log_con, type = "message")

script_status <- list()
run_author <- function(fname) {
  cat("\n\n########## SOURCING", fname, "##########\n")
  t0 <- Sys.time()
  res <- tryCatch({
    source(file.path(code_dir, fname), echo = TRUE, max.deparse.length = Inf,
           local = globalenv(), encoding = "UTF-8")
    "ok"
  }, error = function(e) paste("ERROR:", conditionMessage(e)))
  dt <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  cat("\n########## END", fname, "status:", res, "time_s:", round(dt, 1), "##########\n")
  script_status[[fname]] <<- list(status = res, time_s = round(dt, 1))
}

owd <- setwd(data_dir)  # authors' scripts expect working directory = data folder
run_author("script-Ash2021-1-prep-functions.R")
run_author("script-Ash2021-2-prep-data.R")
run_author("script-Ash2021-4-outputs-various.R")
run_author("script-Ash2021-4-models-mo2.R")
run_author("script-Ash2021-4-models-condition.R")
set.seed(SEED)
run_author("script-Ash2021-powerAnalysis.R")
setwd(owd)

sink(type = "message"); sink(); close(log_con)
invisible(dev.off())

# ---- extract claim values ----------------------------------------------------
library(jsonlite)
r4 <- function(x, d = 6) if (is.null(x)) NULL else signif(unname(x), d)

fx_row <- function(mod, term) {
  sm <- summary(mod)$coefficients
  ci <- suppressMessages(confint(mod))   # authors use default confint (profile)
  av <- anova(mod, type = 3)
  list(est = sm[term, "Estimate"], se = sm[term, "Std. Error"],
       ci = unname(ci[term, ]), av = av)
}
av_row <- function(av, term) list(F = av[term, "F value"], den_df = av[term, "DenDF"],
                                  p = av[term, "Pr(>F)"])

claims <- list()
have_rate1 <- exists("mod_rate1")
have_cond1 <- exists("mod_condition1")

if (have_rate1) {
  capture.output({
    print(summary(mod_rate1)); print(confint(mod_rate1)); print(anova(mod_rate1, type = 3))
    print(MuMIn::r.squaredGLMM(mod_rate1))
  }, file = file.path(out_dir, "model1_smr_full.txt"))
  ci_all <- suppressMessages(confint(mod_rate1))
  sm <- summary(mod_rate1)$coefficients
  av <- anova(mod_rate1, type = 3)
  N <- nobs(mod_rate1)
  n_txt <- sprintf("N=%d (LL=%d, EE=%d; male=%d, female=%d; families=%d; batches=%d)",
                   N, sum(tb_smr$geno_vgll3 == "LL"), sum(tb_smr$geno_vgll3 == "EE"),
                   sum(tb_smr$sex == "male"), sum(tb_smr$sex == "female"),
                   length(unique(tb_smr$family)), length(unique(tb_smr$batch)))
  mk <- function(id, term, aterm, extra = "") {
    a <- av_row(av, aterm)
    list(id = id, status = "ok", value = r4(sm[term, "Estimate"]), p = r4(a$p),
         ci = r4(ci_all[term, ]), se = r4(sm[term, "Std. Error"]), F = r4(a$F),
         den_df = r4(a$den_df),
         notes = paste0("mod_rate1 (authors' script-Ash2021-4-models-mo2.R), lmerTest REML; term '",
                        term, "'; CI = profile confint(); p/F/DenDF = anova(type=3) Satterthwaite for '",
                        aterm, "'. ", n_txt, ". ", extra))
  }
  claims[["C1"]] <- mk("C1", "log10(weight)", "log10(weight)")
  claims[["C2"]] <- mk("C2", "geno_vgll3LL", "geno_vgll3",
                       "Type III F for the main effect is tested with sum-to-zero-type contrasts by lmerTest, so its p need not equal the t-test p of the treatment-coded coefficient.")
  t_p <- sm["geno_vgll3LL:sexmale", "Pr(>|t|)"]
  claims[["C3"]] <- mk("C3", "geno_vgll3LL:sexmale", "geno_vgll3:sex",
                       sprintf("Coefficient t-test p = %.4f. Paper prints p=.117 (Table A1) and p=.69 (Results text).", t_p))
  s <- sigma(mod_rate1)
  claims[["C4"]] <- list(id = "C4", status = "ok", value = r4(s),
    notes = sprintf("sigma(mod_rate1). CV of residuals = sigma*ln(10)*100 = %.3f%% (paper: 6.19%%). Simple model mod_rate3 sigma = %.5f (paper 0.0271). %s",
                    s * log(10) * 100, if (exists("mod_rate3")) sigma(mod_rate3) else NA, n_txt))
} else {
  for (id in c("C1", "C2", "C3", "C4"))
    claims[[id]] <- list(id = id, status = "not_computable",
                         reason = paste("mod_rate1 not created by author pipeline:",
                                        script_status[["script-Ash2021-4-models-mo2.R"]]$status))
}

if (have_cond1) {
  capture.output({
    print(summary(mod_condition1)); print(confint(mod_condition1)); print(anova(mod_condition1, type = 3))
  }, file = file.path(out_dir, "model2_condition_full.txt"))
  smc <- summary(mod_condition1)$coefficients
  cic <- suppressMessages(confint(mod_condition1))
  avc <- anova(mod_condition1, type = 3)
  a <- av_row(avc, "geno_vgll3")
  claims[["C5"]] <- list(id = "C5", status = "ok", value = r4(smc["geno_vgll3LL", "Estimate"]),
    p = r4(a$p), ci = r4(cic["geno_vgll3LL", ]), F = r4(a$F), den_df = r4(a$den_df),
    notes = sprintf("mod_condition1 (authors' script-Ash2021-4-models-condition.R), REML; condition = weight/(length_standard/10)^3*100 as in code. p/F = anova(type=3) for geno_vgll3; coefficient t-test p = %.4f. N=%d.",
                    smc["geno_vgll3LL", "Pr(>|t|)"], nobs(mod_condition1)))
} else {
  claims[["C5"]] <- list(id = "C5", status = "not_computable",
                         reason = paste("mod_condition1 not created:",
                                        script_status[["script-Ash2021-4-models-condition.R"]]$status))
}

if (exists("tb_powersim_b1")) {
  pw <- as.data.frame(tb_powersim_b1)
  pw$effect_pct <- round((10^pw$c_b1) * 100 - 100, 4)
  write.csv(pw, file.path(out_dir, "power_vgll3.csv"), row.names = FALSE)
  if (exists("tb_powersim_b12")) {
    pw12 <- as.data.frame(tb_powersim_b12)
    pw12$effect_pct <- round((10^pw12$c_b12) * 100 - 100, 4)
    write.csv(pw12, file.path(out_dir, "power_vgll3xsex.csv"), row.names = FALSE)
  }
  hit <- pw$effect_pct[pw$power >= 0.8]
  mde <- if (length(hit)) min(hit) else NA
  claims[["C6"]] <- list(id = "C6", status = if (is.na(mde)) "not_computable" else "ok",
    value = mde,
    notes = sprintf("Authors' script-Ash2021-powerAnalysis.R run once, sequentially (multidplyr removed), set.seed(%d) before sourcing; 10000 sims per grid point, grid seq(1,5,0.25)%%. Smallest grid effect with power>=0.8. Power by grid: %s. Full table: outputs/power_vgll3.csv",
                    SEED, paste(sprintf("%.2f%%:%.4f", pw$effect_pct, pw$power), collapse = ", ")))
  if (is.na(mde)) claims[["C6"]]$reason <- "No grid point reached power 0.8"
} else {
  claims[["C6"]] <- list(id = "C6", status = "not_computable",
                         reason = paste("power simulation failed:",
                                        script_status[["script-Ash2021-powerAnalysis.R"]]$status))
}

# ---- sensitivity-free extras: save SMR table ---------------------------------
if (exists("tb_smr"))
  write.csv(as.data.frame(tb_smr)[, c("ID_fish", "ID_sample", "family", "batch", "weight", "mass",
                                      "SMR", "avgTemp", "condition", "geno_vgll3", "sex", "use")],
            file.path(out_dir, "tb_smr.csv"), row.names = FALSE)

pkgs <- c("lme4", "lmerTest", "mclust", "MuMIn", "cvms", "tidyverse", "dplyr", "lubridate",
          "readxl", "car", "sjPlot", "ggeffects", "janitor", "glue", "Matrix", "jsonlite")
sw <- c(R = paste(R.version$major, R.version$minor, sep = "."),
        sapply(pkgs, function(p) tryCatch(as.character(packageVersion(p)), error = function(e) NA)))

runtime <- round(as.numeric(difftime(Sys.time(), t_start, units = "secs")), 1)
res <- list(
  paper_id = "ee-2021-salmon-smr",
  run = list(script = "code/reproduce.R", used_author_code = TRUE, runtime_s = runtime,
             software = as.list(sw), seed = SEED,
             author_scripts = script_status,
             notes = "Author scripts sourced from code/author_run (copies of code/author with only axomatic, plotting and multidplyr lines commented out; see steps.log). Author console output: outputs/author_run_output.txt."),
  claims = unname(claims)
)
write_json(res, file.path(out_dir, "results.json"), auto_unbox = TRUE, pretty = TRUE,
           digits = NA, null = "null", na = "null")
cat("Wrote", file.path(out_dir, "results.json"), "runtime_s =", runtime, "\n")
print(lapply(claims, function(x) x[c("id", "status", "value", "p")]))
