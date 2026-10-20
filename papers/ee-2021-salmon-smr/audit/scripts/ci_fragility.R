d <- read.csv(commandArgs(TRUE)[1])
for (k in c("family","batch","geno_vgll3","sex")) d[[k]] <- factor(d[[k]])
f <- function(dd) { m <- lmerTest::lmer(log10(SMR) ~ log10(weight) + geno_vgll3*sex + avgTemp + (1|family)+(1|batch), data = dd)
  ci <- suppressWarnings(suppressMessages(confint(m))); round(ci[c("(Intercept)","log10(weight)","avgTemp"),], 5) }
print(f(d))
set.seed(42); d2 <- d; d2$SMR <- d2$SMR * (1 + rnorm(nrow(d), sd = 1e-12)); print(f(d2))
d3 <- d; d3$avgTemp <- signif(d3$avgTemp, 8); print(f(d3))
d4 <- d; d4$family <- as.numeric(as.character(d4$family)); d4$batch <- as.numeric(as.character(d4$batch)); print(f(d4))
