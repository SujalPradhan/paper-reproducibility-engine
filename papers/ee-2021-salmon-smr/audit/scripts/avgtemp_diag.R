# Diagnostic: does excluding logger tank "10_0" (as readr<2 type-guessing would) move model 1 toward the paper?
suppressMessages({library(dplyr); library(lubridate); library(readr); library(readxl)})
dd <- commandArgs(TRUE)[1]; csv <- commandArgs(TRUE)[2]
tl <- suppressMessages(read_delim(file.path(dd, "data-Ash2021-temp-loggers-small-tanks-Dec2020.txt")))
cat("readr", as.character(packageVersion("readr")), "tank column class:", class(tl$tank), "\n")
tl <- tl %>% mutate(dateTime = ymd_hms(dateTime), tankc = as.character(tank))
ind <- read_xlsx(file.path(dd, "data-Ash2021-sampled-fish.xlsx")) %>% mutate(date = date(dmy(date)))
mk <- function(drop10) {
  one <- tl %>% filter(dateTime < ymd("2020 07 15")) %>%
    mutate(tn = suppressWarnings(as.numeric(stringr::str_extract(tankc, "\\-*\\d+\\.*\\d*")))) %>%
    filter(tn %in% 1:14, !(drop10 & tankc == "10_0")) %>% group_by(dateTime) %>% summarise(temp = mean(temp, na.rm = TRUE))
  ind %>% rowwise() %>% mutate(avgTemp2 = mean(one$temp[one$dateTime > (date - days(5)) & one$dateTime < (date - days(2))])) %>% ungroup() %>% select(ID_fish, avgTemp2)
}
d <- read.csv(csv); for (k in c("family","batch","geno_vgll3","sex")) d[[k]] <- factor(d[[k]])
for (drop10 in c(FALSE, TRUE)) {
  x <- left_join(d, mk(drop10), by = "ID_fish")
  cat("\ndrop tank 10_0 =", drop10, " max|avgTemp2-avgTemp| =", signif(max(abs(x$avgTemp2 - x$avgTemp)), 3),
      " batch1-8 mean", round(mean(x$avgTemp2[as.numeric(as.character(x$batch)) <= 8]), 3),
      " batch9-10 mean", round(mean(x$avgTemp2[as.numeric(as.character(x$batch)) >= 9]), 3), " overall", round(mean(x$avgTemp2), 3), "\n")
  m <- lmerTest::lmer(log10(SMR) ~ log10(weight) + geno_vgll3*sex + avgTemp2 + (1|family)+(1|batch), data = x); a <- anova(m, type = 3)
  cat(sprintf("AIC %.3f sigma %.5f CV %.3f%% b_mass %.4f b_geno %.4f b_sex %.4f b_temp %.4f b_int %.4f F_mass %.3f DenDF_mass %.3f DenDF_geno %.3f DenDF_sex %.3f DenDF_int %.3f p_geno %.3f p_int %.3f\n",
    AIC(m), sigma(m), sigma(m)*log(10)*100, lme4::fixef(m)[2], lme4::fixef(m)[3], lme4::fixef(m)[4], lme4::fixef(m)[5], lme4::fixef(m)[6],
    a[1,"F value"], a[1,"DenDF"], a[2,"DenDF"], a[3,"DenDF"], a[5,"DenDF"], a[2,"Pr(>F)"], a[5,"Pr(>F)"]))
}
