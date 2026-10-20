
tb_indivData %>% nrow()
tb_indivData %>% filter(use > 0.5) %>% nrow()
# N_total tested = 159
# N in analysis 150
# 9 excluded
#   4 for measurements failure
#   2 for pump failure
#   2 for loss of ID
#   1 for bad O2 reading ("low resulution")

# sizes
tb_smr$weight %>% meanSem()
tb_smr$weight %>% meanSD()
tb_smr %>% group_by(geno_vgll3) %>%
  summarise(w = meanSD(weight),rng_w = rangePrint(weight),l=meanSD(length_standard), rng_l = rangePrint(length_standard))

# family counts
tb_smr %>% group_by(family) %>%
  summarize(n=n(),vgll3=paste(unique(geno_vgll3),collapse=",")) %>% 
  pull(n) %>% meanSD()
# num tested for different familes/tanks:
#   12 tested for almost all families excp:
#   11: family 2,3,9,11,14
#   10: family 10
#   9:  family 7, 8
#   8:  family 12 (LL)

# genotype family sex number table
#EE table
tb_EE <- tb_smr %>%
  filter(geno_vgll3=="EE", use > 0.5) %>%
  group_by(family) %>%
  summarise(
    n_M = sum(sex=="male"),
    n_F = sum(sex=="female"),
    
  ) %>% 
  janitor::adorn_totals() %>%
  funkyTranspose() %>% 
  print()
#LL table
tb_LL <- tb_smr %>%
  filter(geno_vgll3=="LL", use > 0.5) %>%
  group_by(family) %>%
  summarise(
    n_M = sum(sex=="male"),
    n_F = sum(sex=="female"),
    
  ) %>% 
  janitor::adorn_totals() %>%
  funkyTranspose() %>% 
  print()   

# EE
# 2 3 7 8 9 11 13 Total
# n_M 6 7 3 5 5  5  4    35 
# n_F 5 4 6 4 6  6  8    39
# LL
# 1 4 5 6 10 12 14 Total
# n_M 4 8 6 3  5  4  4    34 76
# n_F 8 3 6 9  5  4  7    42

# sex and genotype counts
tb_smr %>% group_by(geno_vgll3) %>% 
  summarise(
    n=n(), 
    n_fam=length(unique(family)), 
    p_male = sum(sex=="male")/n(),
    weight = meanSem(weight)
  )
# 74 EE and 76LL, 0.47% and 0.44% male

# Temperature before respirometry:
tb_smr %>% group_by(batch) %>% summarise(t = meanSD(avgTemp,3,20) )
tb_smr %>% filter(!batch %in% c(9,10)) %>% pull(avgTemp) %>% meanSD()
tb_smr %>% filter(batch %in% c(9,10)) %>% pull(avgTemp) %>% meanSD()
#10.17 for all batches except the two last ones at 10.64

# Temperature during respirometry
tb_respirometry %>% mutate(batch = substr(ID_fish,0,2)) %>% group_by(batch) %>% summarise(t=meanSD(Temp,3,3))
tb_respirometry %>% summarise(t=meanSD(Temp,3,3))

# degree days:
# degdays in Lammi:
f_avgTemp(tb_tempLog_one, ymd(20200315), ymd(20200715))
# 7.38 in 122 days = 900.36 degdays
# 7.2°C for 152 days = 1094 
# total 2158 degdays

# Missing slopes
tb_missing_slopes <- tb_respirometry %>%
  filter(ID_fish %in% tb_smr$ID_fish)%>%
  group_by(ID_fish) %>%
  summarise(
    total_phases = Phase %>% numextract() %>% max(),
    used_phases = length(unique(Phase)),
    missing_phases = total_phases - used_phases
  ) %>% print(n=150)
tb_missing_slopes$missing_phases %>% meanSD()
tb_missing_slopes$used_phases %>% meanSD()
tb_missing_slopes$total_phases %>% mean()
tb_missing_slopes$missing_phases %>% sum()
# Avg 9 missing slopes
# avg 47 slopes used
# Total of 57 slopes
# Total amount of slopes removed was: 1387

# Minimum O2 concentrations reached
tb_resp_raw %>%
  filter(!str_detect(Phase,"F")) %>%
  group_by(name_file,Channel,Phase) %>%
  summarise(o2min = min(Ox)) %>%
  # filter(o2min <  6) %>%  nrow()
  ungroup() %>% pull(o2min) %>% meanSD()

# 10 cases of o2 below 6 mg/l
# 1 case of o2 below 5 mg/l

# % drops in DO
tb_resp_raw %>%
  filter(!str_detect(Phase,"F")) %>%
  group_by(name_file,Channel,Phase) %>%
  summarise(o2Max = max(Ox), o2Min = min(Ox), o2Drop = 1-o2Min/o2Max) %>%
  #pull(o2Drop) %>% hist()
  pull(o2Drop) %>% meanSD()

# Mean R2 = 0.9965
tb_respirometry$R2 %>% meanSD(3,3)

# Avg background respiration
tb_respirometry$BR %>% meanSD()



