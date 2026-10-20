mod_condition1 <- lmerTest::lmer(
  formula = condition ~ geno_vgll3*sex + (1|batch) + (1|family),
  data = tb_smr 
)
mod_condition1 %>% summary()
mod_condition1 %>% confint()
mod_condition1 %>% sjPlot::plot_model()
mod_condition1 %>% anova(type=3)
mod_condition1 %>% residuals() %>% qqnorm()
mod_condition1 %>% plot()
MuMIn::r.squaredGLMM(mod_condition1)

mod_condition1.5 <- lmerTest::lmer(
  formula = condition ~ geno_vgll3 + sex +(1|batch) + (1|family),
  data = tb_smr
)
mod_condition1.5 %>% summary()
mod_condition1.5 %>% confint()
mod_condition1.5 %>% sjPlot::plot_model()
mod_condition1.5 %>% anova(type=2)
mod_condition1.5 %>% residuals() %>% qqnorm()
mod_condition1.5 %>% plot()
MuMIn::r.squaredGLMM(mod_condition1.5)


mod_condition2 <- lmerTest::lmer(
  formula = condition ~ sex +(1|batch) + (1|family),
  data = tb_smr
)
mod_condition2 %>% summary()
mod_condition2 %>% confint()
mod_condition2 %>% sjPlot::plot_model()
mod_condition2 %>% anova(type=2)
mod_condition2 %>% residuals() %>% qqnorm()
mod_condition2 %>% plot()
MuMIn::r.squaredGLMM(mod_condition2)

AIC(mod_condition1,mod_condition1.5,mod_condition2)

# Cross validation (split based on batch number)
cvms::cross_validate(
  data = tb_smr %>% mutate(.folds=factor(ifelse(batch %in% c(1,3,5,7,9),1,2))),
  formulas = c(
    "condition ~ geno_vgll3*sex + (1|batch) + (1|family)",
    "condition ~ geno_vgll3 + sex + (1|batch) + (1|family)",
    "condition ~ sex + (1|batch) + (1|family)"
  ),
  family="gaussian",
  REML=T) %>% view()






