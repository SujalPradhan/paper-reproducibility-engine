library(tidyverse)
library(lubridate)
library(glue)
library(mclust)
library(lme4)
# [REPRO-EDIT axomatic] library(axomatic) # download from devtools::install_github("eiriksen/axomatic")
library(car)
library(readxl)

options(na.action = "na.fail") 

# Table of tank densities
tb_tankDensities <-
  read_delim("data-Ash2021-tank-densities.txt") %>%
  mutate(tankDensity = n_fish)

# Temperature log
tb_tempLog <-
  read_delim("data-Ash2021-temp-loggers-small-tanks-Dec2020.txt") %>%
  mutate(
    dateTime = ymd_hms(dateTime),
    tank = dplyr::recode(tank,"1_10"="10") %>% numextract()
  ) %>% 
  filter(
    dateTime < ymd("2020 07 15"),
    tank %in% c(1:14)
  ) 

# Simplified temperature log
tb_tempLog_one <-
  tb_tempLog %>%
  group_by(dateTime) %>%
  summarise(temp=mean(temp,na.rm=T))

# Mean temp for all tanks
tb_tankTemp <- 
  tb_tempLog %>%
  group_by(tank) %>%
  summarise(temp_mean = mean(temp,na.rm=T))

# Table of genotypes and sex for each individual
tb_genotypes <-
  read_delim("data-Ash2021-genotypes.txt")

# Table of raw respirometry data
tb_resp_raw <- 
  list.files(pattern = "*.resp - FishResp.txt", recursive=T ) %>% 
  lapply(modify_respfile) %>% 
  bind_rows() 

# Table with various data for each individuals
tb_indivData  <- 
  read_xlsx("data-Ash2021-sampled-fish.xlsx")%>%
  group_by(ID_fish)%>%
  mutate(
    date = date(dmy(date)),
    condition = ((weight)/(length_standard/10)^3)*100,
    avgTemp = f_avgTemp(tb_tempLog_one, date-days(5), date-days(2))
    ) %>%
  ungroup() %>%
  left_join(tb_genotypes, by="ID_sample") %>%
  left_join(tb_tankDensities, by=c("family"="tank")) %>%
  left_join(tb_tankTemp, by=c("family"="tank")) %>%
  filter(!is.na("family"))

# Table with non-raw respirometry data
tb_respirometry <- 
  read.delim(file = "data-Ash2021-respirometry.txt") %>%
  rename(
    chamber_ch = Chamber.No,
    ID_fish    = Ind,
    mass       = Mass,
    volume_ch  = Volume,
    dateTime   = Date.Time
  )  %>%
  mutate(
    dateTime = ymd_hms(dateTime),
    hour = hour(dateTime)
    ) %>%
  left_join( 
    y  = tb_indivData,
    by = "ID_fish"
  )

# Complete table with individual info and SMR calculated using MLND
tb_smr <-
  tb_respirometry %>%
  group_by(
    ID_fish, mass, volume_ch, chamber_ch
  ) %>% 
  summarise(
    rate    = calcSMR(MR.mass)$mlnd,
    rate_p  = calcSMR(MR.mass)$quant[3],
    SMR     = calcSMR(MR.abs)$mlnd %>% unname(),
    CVmlnd  = calcSMR(MR.mass,G=1:4)$CVmlnd,
    time_start = dateTime %>% min(),
    time_end = dateTime %>% max()
  ) %>%
  ungroup() %>%
  left_join( 
    y  = tb_indivData,
    by = "ID_fish"
  ) %>%
  group_by(family) %>%
  mutate(
    m_SMR = lm(log(SMR)~log(mass)) %>% residuals()
    ) %>%
  ungroup() %>%
  filter(use > 0.5) %>%
  mutate(
    ID_sample = factor(ID_sample),
    family = factor(family),
    chamber = factor(chamber),
    geno_vgll3 = factor(geno_vgll3),
    sex = factor(sex)
  )

