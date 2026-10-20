tb_smr_summary <- 
  tb_smr %>%
  group_by(geno_vgll3) %>%
  summarize(
    y_smr = mean(SMR),
    x_weight = mean(weight),
    y_m = mean(m_SMR),
    y_len = mean(length_standard),
    ymin = y_smr-sem(SMR),
    ymax = y_smr+sem(SMR),
    xmin = x_weight-sem(weight),
    xmax = x_weight+sem(weight),
    ymax_m = y_m+sem(m_SMR),
    ymin_m = y_m-sem(m_SMR),
    ymin_len = y_len-sem(length_standard),
    ymax_len = y_len+sem(length_standard),
    geno_vgll3 = paste(geno_vgll3[1],"X",sep="")
  )

plo_smr <-  
    ggplot(tb_smr) +
    aes(x=weight,y=SMR, col=geno_vgll3,shape=geno_vgll3,fill=geno_vgll3, group=geno_vgll3) +
    
    geom_point(size=13,alpha=0.85,stroke=4) +
    geom_smooth(method=lm,data=subset(tb_smr, geno_vgll3=="LL"),size=5,formula=y~x,se=F,col=llCol) +
    geom_smooth(method=lm,data=subset(tb_smr, geno_vgll3=="EE"),size=5,linetype="dashed",formula=y~x,se=F,col=eeCol) +
    
    scale_shape_manual(values=c("LL"=0,"EE"=1,"EEX"=21,"LLX"=22))+
    scale_color_manual(values=c("LL"=llCol,"EE"=eeCol,"EEX"="black","LLX"="black")) +
    scale_fill_manual(values=c("LL"=llCol,"EE"=eeCol,"EEX"=eeCol,"LLX"=llCol)) +
    
    geom_errorbarh(data=tb_smr_summary,aes(y=y_smr,xmax=xmax,xmin=xmin,x=x_weight),size=3,height=0.05,col="black")+
    geom_point(data=tb_smr_summary,aes(y=y_smr,x=x_weight),size=18,alpha=1,stroke=4)+
    labs(
      title ="Standard Metabolic Rate (mg O<sub>2</sub> L<sup>-1</sup> h<sup>-1</sup>)",
      x = "Body mass (g)",
      y = ""
    )+
    axis_x(0.5,2,ticks=0.5,upperPad=-0.1,trans="log")+
    axis_y(from=0.1,0.35,ticks=0.05,lowerPad=0.02,upperPad=-0.05,trans="log")

ggsave(
  plo_smr + theme_print, 
  filename = "plot - smr.png", 
  width=output_width*0.7, 
  height=output_height, 
  units="mm", 
  dpi=601,
  bg = "transparent",
)  
