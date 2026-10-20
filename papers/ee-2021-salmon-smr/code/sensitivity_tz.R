# Diagnostic S2 (post-hoc, NOT graded): author prep + mod_rate1 with Sys.setenv(TZ="Europe/Helsinki").
args <- commandArgs(trailingOnly = FALSE); f <- sub("^--file=", "", args[grep("^--file=", args)])
root <- normalizePath(file.path(dirname(f), "..")); .libPaths(c(file.path(root, "env", "Rlib"), .libPaths()))
Sys.setenv(TZ = "Europe/Helsinki")
owd <- setwd(file.path(root, "data"))
invisible(capture.output(suppressWarnings(suppressMessages({
  source(file.path(root, "code/author_run/script-Ash2021-1-prep-functions.R"), local = globalenv())
  source(file.path(root, "code/author_run/script-Ash2021-2-prep-data.R"), local = globalenv())}))))
setwd(owd)
m <- lmerTest::lmer(log10(SMR) ~ log10(weight) + geno_vgll3*sex + avgTemp + (1|family)+(1|batch), data = tb_smr)
sm <- summary(m)$coefficients; av <- anova(m, type = 3); ci <- suppressMessages(confint(m))
s2 <- list(label = "S2 (post-hoc diagnostic): session TZ=Europe/Helsinki; everything else identical",
  avgTemp_mean = mean(tb_smr$avgTemp), avgTemp_batches1to8 = mean(tb_smr$avgTemp[!tb_smr$batch %in% 9:10]),
  avgTemp_batches9_10 = mean(tb_smr$avgTemp[tb_smr$batch %in% 9:10]),
  C1 = list(value = sm["log10(weight)", "Estimate"], ci = unname(ci["log10(weight)", ]), F = av["log10(weight)", "F value"], den_df = av["log10(weight)", "DenDF"]),
  C2 = list(value = sm["geno_vgll3LL", "Estimate"], ci = unname(ci["geno_vgll3LL", ]), p = av["geno_vgll3", "Pr(>F)"], F = av["geno_vgll3", "F value"]),
  C3 = list(value = sm["geno_vgll3LL:sexmale", "Estimate"], ci = unname(ci["geno_vgll3LL:sexmale", ]), p = av["geno_vgll3:sex", "Pr(>F)"]),
  C4 = list(value = sigma(m)))
sf <- file.path(root, "outputs", "sensitivity.json"); old <- jsonlite::read_json(sf)
old[["S2_TZ_Helsinki_posthoc"]] <- s2
jsonlite::write_json(old, sf, auto_unbox = TRUE, pretty = TRUE, digits = NA)
str(s2)
