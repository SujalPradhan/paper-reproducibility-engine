# Diagnostic: model 1 with avgTemp computed (a) as in our R 4.6.1 run (midnight logger rows lost by ymd_hms),
# (b) keeping midnight rows, as R 4.0.4 would (as.character.POSIXct kept 00:00:00 before R 4.3).
suppressMessages({library(dplyr); library(lubridate); library(readr); library(readxl)})
dd <- commandArgs(TRUE)[1]; csv <- commandArgs(TRUE)[2]
tl0 <- suppressMessages(read_delim(file.path(dd, "data-Ash2021-temp-loggers-small-tanks-Dec2020.txt")))
ind <- read_xlsx(file.path(dd, "data-Ash2021-sampled-fish.xlsx")) %>% mutate(date = date(dmy(date)))
num <- function(s) as.numeric(stringr::str_extract(s, "\\-*\\d+\\.*\\d*"))
mk <- function(keep_midnight) {
  dt <- if (keep_midnight) tl0$dateTime else suppressWarnings(ymd_hms(tl0$dateTime))
  one <- tl0 %>% mutate(dateTime = dt, tank = num(dplyr::recode(tank, "1_10" = "10"))) %>%
    filter(dateTime < ymd("2020 07 15"), tank %in% 1:14) %>% group_by(dateTime) %>% summarise(temp = mean(temp, na.rm = TRUE))
  ind %>% rowwise() %>% mutate(avgTemp2 = mean(one$temp[one$dateTime > (date - days(5)) & one$dateTime < (date - days(2))])) %>% ungroup() %>% select(ID_fish, avgTemp2)
}
d <- read.csv(csv); for (k in c("family","batch","geno_vgll3","sex")) d[[k]] <- factor(d[[k]])
for (km in c(FALSE, TRUE)) {
  x <- left_join(d, mk(km), by = "ID_fish"); b <- as.numeric(as.character(x$batch))
  cat("\nkeep_midnight =", km, " max|avgTemp2 - committed avgTemp| =", signif(max(abs(x$avgTemp2 - x$avgTemp)), 3),
      " batches1-8", round(mean(x$avgTemp2[b <= 8]), 3), " batches9-10", round(mean(x$avgTemp2[b >= 9]), 3), " overall", round(mean(x$avgTemp2), 3), "\n")
  m <- lmerTest::lmer(log10(SMR) ~ log10(weight) + geno_vgll3*sex + avgTemp2 + (1|family)+(1|batch), data = x); a <- anova(m, type = 3)
  ci <- suppressWarnings(suppressMessages(confint(m)))
  cat(sprintf("M1: AIC %.3f sigma %.5f CV %.3f%% | mass %.5f [%.4f, %.4f] F %.3f DenDF %.3f | geno %.5f F %.4f DenDF %.3f p %.4f | sex %.5f DenDF %.3f p %.4f | temp %.5f DenDF %.3f p %.4f | int %.5f [%.4f, %.4f] DenDF %.3f p %.4f | Intercept %.4f [%.4f, %.4f]\n",
    AIC(m), sigma(m), sigma(m)*log(10)*100, lme4::fixef(m)[2], ci["log10(weight)",1], ci["log10(weight)",2], a[1,"F value"], a[1,"DenDF"],
    lme4::fixef(m)[3], a[2,"F value"], a[2,"DenDF"], a[2,"Pr(>F)"], lme4::fixef(m)[4], a[3,"DenDF"], a[3,"Pr(>F)"],
    lme4::fixef(m)[5], a[4,"DenDF"], a[4,"Pr(>F)"], lme4::fixef(m)[6], ci[9,1], ci[9,2], a[5,"DenDF"], a[5,"Pr(>F)"], lme4::fixef(m)[1], ci[4,1], ci[4,2]))
  print(lme4::VarCorr(m), digits = 4)
  m3 <- lmerTest::lmer(log10(SMR) ~ log10(weight) + avgTemp2 + (1|family)+(1|batch), data = x); a3 <- anova(m3, type = 2)
  cat(sprintf("M3 simple: AIC %.3f sigma %.5f CV %.3f%% mass %.5f F %.3f DenDF %.3f temp %.5f\n", AIC(m3), sigma(m3), sigma(m3)*log(10)*100, lme4::fixef(m3)[2], a3[1,"F value"], a3[1,"DenDF"], lme4::fixef(m3)[3]))
}
