
mod_rate1 <- lmerTest::lmer(
  formula = log10(SMR) ~ log10(weight) + geno_vgll3*sex + avgTemp + (1|family)+(1|batch),
  data = tb_smr 
)
mod_rate1 %>% summary()
mod_rate1 %>% confint()
mod_rate1 %>% sjPlot::plot_model()
mod_rate1 %>% residuals() %>% qqnorm()
mod_rate1 %>% plot()
mod_rate1 %>% anova(type=3)
MuMIn::r.squaredGLMM(mod_rate1)


mod_rate1.5 <- lmerTest::lmer(
  formula = log10(SMR) ~ log10(weight) + geno_vgll3 + sex + avgTemp + (1|family)+(1|batch),
  data = tb_smr 
)
mod_rate1.5 %>% summary()
mod_rate1.5 %>% confint()
mod_rate1.5 %>% sjPlot::plot_model()
mod_rate1.5 %>% residuals() %>% qqnorm()
mod_rate1.5 %>% plot()
mod_rate1.5 %>% anova(type=3)
MuMIn::r.squaredGLMM(mod_rate1.5)


mod_rate2 <- lmerTest::lmer(
  formula = log10(SMR) ~ log10(weight) + sex + avgTemp + (1|family)+(1|batch),
  data = tb_smr
)
mod_rate2 %>% summary()
mod_rate2 %>% confint()
mod_rate2 %>% sjPlot::plot_model()
mod_rate2 %>% residuals() %>% qqnorm()
mod_rate2 %>% plot()
mod_rate2 %>% anova(type=3)
MuMIn::r.squaredGLMM(mod_rate2)

mod_rate3 <- lmerTest::lmer(
  formula = log10(SMR) ~ log10(weight) + avgTemp + (1|family)+(1|batch),
  data = tb_smr
)
mod_rate3 %>% summary()
mod_rate3 %>% confint()
mod_rate3 %>% sjPlot::plot_model()
mod_rate3 %>% residuals() %>% qqnorm()
mod_rate3 %>% plot()
mod_rate3 %>% anova(type=2)
MuMIn::r.squaredGLMM(mod_rate3)


AIC(mod_rate1,mod_rate1.5,mod_rate2,mod_rate3)

# Cross validation (split based on batch number)
cvms::cross_validate(
  data = tb_smr %>% mutate(.folds=factor(ifelse(batch %in% c(1,3,5,7,9),1,2))) %>%
    mutate(logsmr = log(SMR), logweight=log(weight)),
  models = c(
    "logsmr ~ logweight + sex*geno_vgll3 + avgTemp + (1|family)",
    "logsmr ~ logweight + sex + geno_vgll3 + avgTemp + (1|family)",
    "logsmr ~ logweight + sex + avgTemp + (1|family)",
    "logsmr ~ logweight + avgTemp + (1|family)"
  ),
  family="gaussian",
  REML=T) %>% view()


# [REPRO-SKIP plotting] # Plots for model coefficients and predicted means below:
# [REPRO-SKIP plotting] 
# [REPRO-SKIP plotting] # Table of coefficients
# [REPRO-SKIP plotting] tb_coeff <-
# [REPRO-SKIP plotting]   as.data.frame(confint(mod_rate1)) %>%
# [REPRO-SKIP plotting]   rownames_to_column("ID") %>%
# [REPRO-SKIP plotting]   rowid_to_column("ID_n") %>%
# [REPRO-SKIP plotting]   rename(lower=`2.5 %`,upper=`97.5 %`) %>%
# [REPRO-SKIP plotting]   left_join(
# [REPRO-SKIP plotting]     by="ID",
# [REPRO-SKIP plotting]     y = summary(mod_rate1)$coefficients %>% as.data.frame() %>% rownames_to_column("ID")
# [REPRO-SKIP plotting]   ) %>%
# [REPRO-SKIP plotting]   mutate(
# [REPRO-SKIP plotting]     ID = dplyr::recode(ID,
# [REPRO-SKIP plotting]                        "sexmale" = "sex (m)",
# [REPRO-SKIP plotting]                        "log10(weight)"="log<sub>10</sub>body mass",
# [REPRO-SKIP plotting]                        "geno_vgll3LL:sexmale"="<i>vgll3</i>(LL):sex(m)",
# [REPRO-SKIP plotting]                        "geno_vgll3LL"="<i>vgll3</i> (LL)",
# [REPRO-SKIP plotting]                        "(Intercept)"="intercept",
# [REPRO-SKIP plotting]     ),
# [REPRO-SKIP plotting]     ID = fct_reorder(factor(ID),-ID_n),
# [REPRO-SKIP plotting]     labpos = ifelse(Estimate<0.6,yes=0.07,no=0.5)
# [REPRO-SKIP plotting]   ) %>%
# [REPRO-SKIP plotting]   filter(!ID %in% c(".sigma",".sig02",".sig01","intercept"))
# [REPRO-SKIP plotting] 
# [REPRO-SKIP plotting] # plot of coefficients
# [REPRO-SKIP plotting] plo_coeff <- 
# [REPRO-SKIP plotting]   ggplot(tb_coeff)+
# [REPRO-SKIP plotting]   aes(x = ID, y = Estimate) + 
# [REPRO-SKIP plotting]   geom_hline(yintercept = 0, color = "darkgray",size=1.5) +
# [REPRO-SKIP plotting]   geom_point(size=10)+
# [REPRO-SKIP plotting]   geom_errorbar(aes(ymax=upper,ymin=lower), size=3,width=0.2)+
# [REPRO-SKIP plotting]   geom_text(aes(label = glue("{round(Estimate,3)}±{round((upper-lower)/2,3)}"), y=labpos), nudge_x = 0,hjust=0, size=25) + 
# [REPRO-SKIP plotting]   scale_x_discrete("") + 
# [REPRO-SKIP plotting]   axis_y(from=-0,to=0.9,ticks=0.3,lowerPad = 0.04,upperPad=0.04)+
# [REPRO-SKIP plotting]   labs(
# [REPRO-SKIP plotting]     title="Model parameter estimates <sub>2</sub><sup>2</sup>",
# [REPRO-SKIP plotting]     subtitle="±95% CI",
# [REPRO-SKIP plotting]     y="",
# [REPRO-SKIP plotting]     x=""
# [REPRO-SKIP plotting]   )+
# [REPRO-SKIP plotting]   coord_flip()
# [REPRO-SKIP plotting] 
# [REPRO-SKIP plotting] ggsave(
# [REPRO-SKIP plotting]   plo_coeff + theme_print + theme_xgrids,
# [REPRO-SKIP plotting]   filename = "plot - coeff smr.png", 
# [REPRO-SKIP plotting]   width=output_width*0.77, 
# [REPRO-SKIP plotting]   height=output_height, 
# [REPRO-SKIP plotting]   units="mm", 
# [REPRO-SKIP plotting]   dpi=600,
# [REPRO-SKIP plotting]   bg = "transparent",
# [REPRO-SKIP plotting] )  
# [REPRO-SKIP plotting] 
# [REPRO-SKIP plotting] # plot of predicted means
# [REPRO-SKIP plotting] plot_predict_rate1 <-
# [REPRO-SKIP plotting]   ggplot(ggeffects::ggpredict(mod_rate1,terms=c("sex","geno_vgll3")))+
# [REPRO-SKIP plotting]   aes(x=x,y=10^predicted*1000,col=group,shape=group)+
# [REPRO-SKIP plotting]   geom_point(size=15, stroke=4,position = position_dodge(width=0.5))+
# [REPRO-SKIP plotting]   geom_errorbar(aes(ymin=10^conf.low*1000,ymax=10^conf.high*1000),width=0.2,size=3,position = position_dodge(0.5))+
# [REPRO-SKIP plotting]   scale_shape_manual(values=c("LL"=15,"EE"=16))+
# [REPRO-SKIP plotting]   scale_color_manual( values=c("LL"=llCol,"EE"=eeCol))+
# [REPRO-SKIP plotting]   labs(
# [REPRO-SKIP plotting]     y="",
# [REPRO-SKIP plotting]     x="",
# [REPRO-SKIP plotting]     title="SMR (mg O<sub>2</sub> L<sup>-1</sup> kg<sup>-1</sup> h<sup>-1</sup>)",
# [REPRO-SKIP plotting]     subtitle="Predicted mean ±95% CI"
# [REPRO-SKIP plotting]   )
# [REPRO-SKIP plotting] 
# [REPRO-SKIP plotting] ggsave(
# [REPRO-SKIP plotting]   plot_predict_rate1 + theme_print + theme_xgrids,
# [REPRO-SKIP plotting]   filename = "plot - predict rate.png", 
# [REPRO-SKIP plotting]   width=output_width/2.3, 
# [REPRO-SKIP plotting]   height=output_height, 
# [REPRO-SKIP plotting]   units="mm", 
# [REPRO-SKIP plotting]   dpi=600,
# [REPRO-SKIP plotting]   bg = "transparent",
# [REPRO-SKIP plotting] )  
# [REPRO-SKIP plotting] 