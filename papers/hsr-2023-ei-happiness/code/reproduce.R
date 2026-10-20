# Reproduction of Hatamnejad et al. (2023) Health Sci Rep 6:e1745, Table 2
# Primary: ONE multivariable gamma GLM (log link), per claims.json methods_steps.
# Usage: Rscript code/reproduce.R [path/to/data_dir]
t0 <- Sys.time()

args_all <- commandArgs(trailingOnly = FALSE)
script_path <- sub("^--file=", "", grep("^--file=", args_all, value = TRUE))
script_dir <- if (length(script_path)) dirname(normalizePath(script_path)) else getwd()
paper_dir <- normalizePath(file.path(script_dir, ".."))
args <- commandArgs(trailingOnly = TRUE)
data_dir <- if (length(args) >= 1) args[1] else file.path(paper_dir, "data")
out_dir <- file.path(paper_dir, "outputs")
dir.create(out_dir, showWarnings = FALSE)

# project-local library (haven installed there by env/install.R)
local_lib <- file.path(paper_dir, "env", "rlib")
if (dir.exists(local_lib)) .libPaths(c(local_lib, .libPaths()))
suppressPackageStartupMessages({ library(haven); library(jsonlite) })

# ---- Load ----
d <- read_sav(file.path(data_dir, "EI_and_Happiness_raw_Data_with_coding.sav"))
stopifnot(nrow(d) == 405, ncol(d) == 90)
d <- zap_labels(d)  # plain numeric codes; factors built explicitly below
stopifnot(!anyNA(d))

# ---- Sanity checks vs Table 1 (not graded) ----
d$happiness <- d$total_Happiness_score / 29
sanity <- c(
  n = nrow(d), male = sum(d$Gender == 1), female = sum(d$Gender == 2),
  age_mean = mean(d$AGE), age_sd = sd(d$AGE),
  introvert = sum(d$Personality_assessment == 1), extrovert = sum(d$Personality_assessment == 2),
  stress_mean = mean(d$Living_stress_score), stress_sd = sd(d$Living_stress_score),
  health_mean = mean(d$self_physical_examination), health_sd = sd(d$self_physical_examination),
  EI_mean = mean(d$EI_score_total), EI_sd = sd(d$EI_score_total),
  happy_mean = mean(d$happiness), happy_sd = sd(d$happiness),
  max_abs_diff_vs_Adj_total = max(abs(d$happiness - d$Adj_total_happiness))
)

# ---- Predictors ----
cat_vars <- c(Gender = 1, Marital_status = 1, Clinical_Grade = 1, University = 1,
              Living = 1, Ethnicity = 1, Job = 0, Salary = 1, Siblings = 1,
              Outstanding_students = 0, Parrents_living_status = 1,
              Personality_assessment = 1, Thinking_immigration = 0,
              exhustion_to_work = 0, No_feeling_at_work = 0,
              Happiness_compared_before_pandemy = 1)
cont_vars <- c("AGE", "Living_stress_score", "self_physical_examination",
               "Appraisal_own_emotions", "Regulation_of_own_emotion",
               "Appraisial_of_others_emotion", "Regulation_others_emotion",
               "Utilization_of_emotions")
for (v in names(cat_vars)) {
  d[[v]] <- relevel(factor(d[[v]]), ref = as.character(cat_vars[[v]]))
}
fml <- reformulate(c(names(cat_vars), cont_vars), response = "happiness")

# Stata-style eform table: exp(b), delta SE, z-based p and 95% CI
eform_table <- function(fit) {
  s <- summary(fit)$coefficients  # dispersion = Pearson chi2 / df (R default)
  b <- s[, 1]; se <- s[, 2]; z <- b / se
  data.frame(term = rownames(s), b = b, se_b = se, expB = exp(b), se_expB = exp(b) * se,
             z = z, p = 2 * pnorm(-abs(z)), ci_lo = exp(b - qnorm(0.975) * se),
             ci_hi = exp(b + qnorm(0.975) * se), row.names = NULL)
}

# ---- Primary model ----
fit <- glm(fml, data = d, family = Gamma(link = "log"))
tab <- eform_table(fit)
disp <- summary(fit)$dispersion

claim_terms <- c(C1 = "Gender2", C2 = "AGE", C3 = "Personality_assessment2",
                 C4 = "Living_stress_score", C5 = "self_physical_examination",
                 C6 = "Regulation_of_own_emotion")

fmt_row <- function(r) sprintf("Exp(B)=%.4f SE=%.4f 95%%CI=[%.4f, %.4f] z=%.3f p=%.4g",
                               r$expB, r$se_expB, r$ci_lo, r$ci_hi, r$z, r$p)
claims_out <- lapply(names(claim_terms), function(id) {
  r <- tab[tab$term == claim_terms[[id]], ]
  if (nrow(r) != 1) return(list(id = id, status = "not_computable",
                                reason = paste("term", claim_terms[[id]], "not in model")))
  list(id = id, status = "ok", value = round(r$expB, 6), p = signif(r$p, 6),
       se = round(r$se_expB, 6), ci = round(c(r$ci_lo, r$ci_hi), 6),
       notes = paste0("Multivariable gamma GLM (log link), n=", nobs(fit), ", term ",
                      claim_terms[[id]], ". ", fmt_row(r),
                      ". Pearson dispersion=", signif(disp, 5), "; z-based p/CI (Stata-style)."))
})

# ---- Sensitivity: univariable models + EI domains with significant covariates ----
uni <- do.call(rbind, lapply(c(names(cat_vars), cont_vars), function(v) {
  f <- glm(reformulate(v, "happiness"), data = d, family = Gamma(link = "log"))
  t <- eform_table(f); t <- t[t$term != "(Intercept)", ]; cbind(variable = v, t)
}))
# map model terms back to variables by exact term name (continuous) or var+level (factor)
term_var <- c(setNames(cont_vars, cont_vars),
              unlist(lapply(names(cat_vars), function(v)
                setNames(rep(v, nlevels(d[[v]])), paste0(v, levels(d[[v]]))))))
sig_cov <- unique(unname(term_var[tab$term[tab$p < 0.05 & tab$term != "(Intercept)"]]))
ei_vars <- cont_vars[4:8]
fml_red <- reformulate(unique(c(ei_vars, sig_cov)), "happiness")
fit_red <- glm(fml_red, data = d, family = Gamma(link = "log"))
tab_red <- eform_table(fit_red)

pick <- function(t, term) { r <- t[t$term == term, ]
  list(value = r$expB, se = r$se_expB, ci = c(r$ci_lo, r$ci_hi), p = r$p) }
sens <- list(
  description = paste("Diagnostic sensitivity analyses (not graded). (a) univariable gamma GLMs,",
                      "one per Table 2 variable; (b) reduced model: 5 EI domains + covariates",
                      "significant (p<0.05) in the primary model."),
  univariable = lapply(setNames(names(claim_terms), names(claim_terms)),
                       function(id) pick(uni, claim_terms[[id]])),
  univariable_all_terms = uni,
  reduced_model = list(formula = deparse(fml_red, width.cutoff = 500L),
                       claims = lapply(setNames(names(claim_terms), names(claim_terms)),
                                       function(id) if (claim_terms[[id]] %in% tab_red$term)
                                         pick(tab_red, claim_terms[[id]]) else NULL),
                       all_terms = tab_red)
)
write_json(sens, file.path(out_dir, "sensitivity.json"), auto_unbox = TRUE,
           digits = NA, pretty = TRUE, null = "null")

# ---- Human-readable output ----
sink(file.path(out_dir, "model_output.txt"))
cat("=== Sanity checks vs Table 1 ===\n"); print(round(sanity, 4))
cat("\n=== Primary model ===\n"); print(fml)
print(summary(fit))
cat("\n=== Stata-style eform table (z-based) ===\n")
print(format(tab, digits = 4), row.names = FALSE)
cat("\n=== Sensitivity: univariable models ===\n")
print(format(uni, digits = 4), row.names = FALSE)
cat("\n=== Sensitivity: reduced model ===\n"); print(fml_red)
print(format(tab_red, digits = 4), row.names = FALSE)
sink()

# ---- results.json ----
pkgs <- c("haven", "jsonlite")
software <- c(list(R = paste(R.version$major, R.version$minor, sep = ".")),
              setNames(lapply(pkgs, function(p) as.character(packageVersion(p))), pkgs))
res <- list(
  paper_id = "hsr-2023-ei-happiness",
  run = list(script = "code/reproduce.R", used_author_code = FALSE,
             runtime_s = round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 2),
             software = software, seed = NULL),
  claims = claims_out
)
write_json(res, file.path(out_dir, "results.json"), auto_unbox = TRUE,
           digits = NA, pretty = TRUE, null = "null")
cat("Wrote", file.path(out_dir, "results.json"), "\n")
