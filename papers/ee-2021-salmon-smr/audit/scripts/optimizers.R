d <- read.csv(commandArgs(TRUE)[1]); for (k in c("family","batch","geno_vgll3","sex")) d[[k]] <- factor(d[[k]])
fm <- log10(SMR) ~ log10(weight) + geno_vgll3*sex + avgTemp + (1|family)+(1|batch)
ctl <- list(default = lme4::lmerControl(),
            bobyqa = lme4::lmerControl(optimizer = "bobyqa"),
            NM = lme4::lmerControl(optimizer = "Nelder_Mead"),
            nlopt_tight = lme4::lmerControl(optimizer = "nloptwrap", optCtrl = list(xtol_abs = 1e-12, ftol_abs = 1e-12, maxeval = 1e5)))
for (n in names(ctl)) { m <- lmerTest::lmer(fm, data = d, control = ctl[[n]]); a <- anova(m, type = 3)
  cat(sprintf("%-12s REMLcrit %.5f AIC %.4f theta %s sigma %.6f b_mass %.6f b_geno %.6f b_int %.6f F_mass %.3f DenDF_mass %.3f DenDF_sex %.3f\n", n, lme4::REMLcrit(m), AIC(m),
    paste(round(lme4::getME(m,"theta"),5), collapse="/"), sigma(m), lme4::fixef(m)[2], lme4::fixef(m)[3], lme4::fixef(m)[6], a["log10(weight)","F value"], a["log10(weight)","DenDF"], a["sex","DenDF"])) }
