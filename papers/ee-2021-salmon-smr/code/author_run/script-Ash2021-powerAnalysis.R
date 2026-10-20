
# formula for the model we want to use
sim_formula <- y~b0+b1*b2

# Function for model to specify the relationship between the dependent and independent variables we want to test
sim_model <- function(b0,b1,b2=0,c_intercept=1,c_b0=0,c_b1=0,c_b2=0,c_b01=0,c_b02=0,c_b12=0,c_b123=0,sd=1){
  result <-
    c_intercept + 
    b0*c_b0 + 
    b1*c_b1 + 
    b2*c_b2 + 
    b0*b1*c_b01 +
    b0*b2*c_b02 + 
    b1*b2*c_b12 +
    b0*b1*b2*c_b123 +
    rnorm(n=length(b0),sd=sd,mean=0)
}

# Simulating a dataset with individuals with different values for independent variables
sim_dataset <- function(n){
  table <- data.frame(
    b0 = rnorm(n = n, mean = 1.07, sd=0.3),
    b1 = c(rep(0,n/2),rep(1,n/2)),
    b2 = c(0,1)
  ) 
  return(table)
}

# Using the functions above,
# Creates "simuls" number of datasets of "n" size, -
# - and tests if a linear model gives a significant result for a given parameter (coeff)
# returns the a number representing the proportion of datasets where a significant result was found
sim_power <- function(n,c_intercept=1,c_b0=0.83, c_b1=0.04,c_b2=0.00,c_b01=0,c_b02=0,c_b12=0,c_b123=0,sd=0.06,coeff=20,simuls=500){
  n_success = 0
  for(i in 1:simuls){
    tb <-
      sim_dataset(n) %>%
      mutate(
        y = sim_model(b0,b1,b2,c_intercept,c_b0,c_b1,c_b2,c_b01,c_b02,c_b12,c_b123,sd)
      )
    pval = summary(lm(sim_formula,data=tb))$coefficients[coeff]
    if (pval < 0.05) sign=T else sign=F
    if (sign) n_success = n_success+1
  }
  return(n_success/simuls)
}

# Note: multidplyr is only to paralell-process the following simulations (with 4 cores).
# [REPRO-SKIP] # Can be removed by commenting out out all rows with multidplyr:: in them, gives same result, just slower
# [REPRO-SKIP] multidplyr::new_cluster(parallel::detectCores()) -> cluster
# [REPRO-SKIP] multidplyr::cluster_copy(cluster,c("sim_power","sim_dataset","sim_model","sim_formula"))
# [REPRO-SKIP] multidplyr::cluster_library(cluster, "dplyr")


# Testing the power to detect an effect of parameter b1 (vgll3, in our case)
# - for different values of b1's coefficient, (effect size of vgll3)
tb_powersim_b1 <- 
  data.frame(
    n = 150,
    c_b1 = log10(seq(from=1,to=5,by=0.25)/100+1)
  ) %>%
  rowwise() %>% 
# [REPRO-SKIP]   multidplyr::partition(cluster) %>%
  mutate(
    power = sim_power(n=n ,c_b1=c_b1, c_b12=-c_b1, coeff=18, sd=0.027, simuls=10000),
  ) %>%
  collect()

# testing the power to detect an interaction between b1 and b2 (vgll3 and sex, in our case)
# -for different values b1 and b2's interaction coefficient (interaction effect size)
tb_powersim_b12 <- 
  data.frame(
    n = 150,
    c_b12 = log10(seq(from=-6,to=6,by=0.5)/100+1)
  ) %>%
  rowwise() %>%
# [REPRO-SKIP]   multidplyr::partition(cluster) %>%
  mutate(
    power = sim_power(n=n, c_b12=c_b12, c_b1=0.04, sd=0.027, coeff=20, simuls=10000)
  ) %>%
  collect()

# [REPRO-SKIP] # plots result of above simulation for vgll3 effect
# [REPRO-SKIP] {(
# [REPRO-SKIP]   plot_powersim_b1 <- 
# [REPRO-SKIP]     ggplot(tb_powersim_b1)+
# [REPRO-SKIP]     aes(x=(10^(c_b1))*100-100,y=power)+
# [REPRO-SKIP]     geom_line(size=2,linetype="dashed")+
# [REPRO-SKIP]     geom_point(size=13)+
# [REPRO-SKIP]     geom_hline(yintercept = 0.8)+
# [REPRO-SKIP]     axis_y(from=0,to=1,ticks=0.2)+
# [REPRO-SKIP]     labs(
# [REPRO-SKIP]       title = "Detection power",
# [REPRO-SKIP]       subtitle = "(*vgll3* genotype effect)",
# [REPRO-SKIP]       x = "Simulated effect size (%)",
# [REPRO-SKIP]       y = ""
# [REPRO-SKIP]     )
# [REPRO-SKIP] )}
# [REPRO-SKIP] ggsave(
# [REPRO-SKIP]   plot_powersim_b1 + theme_print + theme_ygrids,
# [REPRO-SKIP]   filename = "plot - power vgll3.png", 
# [REPRO-SKIP]   width=700, 
# [REPRO-SKIP]   height=output_height, 
# [REPRO-SKIP]   units="mm", 
# [REPRO-SKIP]   dpi=600,
# [REPRO-SKIP]   bg="transparent",
# [REPRO-SKIP] )  
# [REPRO-SKIP] 
# [REPRO-SKIP] # plots result of above simulation for vgll3 sex interaction effect
# [REPRO-SKIP] {(
# [REPRO-SKIP]   plot_powersim_b12 <- 
# [REPRO-SKIP]     ggplot(tb_powersim_b12)+
# [REPRO-SKIP]     aes(x=(10^(c_b12))*100-100,y=power)+
# [REPRO-SKIP]     geom_line(size=2,linetype="dashed")+
# [REPRO-SKIP]     geom_point(size=13)+
# [REPRO-SKIP]     geom_hline(yintercept=0.8)+
# [REPRO-SKIP]     axis_y(from=0,to=1,ticks=0.2)+
# [REPRO-SKIP]     axis_x(from=-6,to=6,ticks=2,pad=0.5)+
# [REPRO-SKIP]     labs(
# [REPRO-SKIP]       title = "Detection power",
# [REPRO-SKIP]       subtitle="(*vgll3* genotype & sex interaction)",
# [REPRO-SKIP]       x = "Simulated interaction effect size (%)",
# [REPRO-SKIP]       y = ""
# [REPRO-SKIP]     )
# [REPRO-SKIP] )}
# [REPRO-SKIP] ggsave(
# [REPRO-SKIP]   plot_powersim_b12 + theme_print + theme_ygrids,
# [REPRO-SKIP]   filename = "plot - power vgll3 x sex.png", 
# [REPRO-SKIP]   width=700, 
# [REPRO-SKIP]   height=output_height, 
# [REPRO-SKIP]   units="mm", 
# [REPRO-SKIP]   dpi=600,
# [REPRO-SKIP]   bg="transparent",
# [REPRO-SKIP] )  
# [REPRO-SKIP] 