#######################
#fit models
#####################

library(terra)
library(tidyterra)
library(MuMIn)
library(tidyverse)
library(amt)

#load
bursts<-readRDS("Outputs/bursts.RDS")
sexmap<-readRDS("Outputs/sexmap.RDS") %>%
    droplevels()
r<-terra::rast("Outputs/CombinedRaster.tif")

# create random steps and add covariates
bursts<-bursts |> 
  mutate(steps = map(steps, function(x) {x |> random_steps(n_control = 15)} ))

bursts_withCovariates<-bursts |> 
  mutate(steps = map(steps, function(x) {x |> extract_covariates(r, where="end")} ))

df<-bursts_withCovariates |> select(id, steps) |> unnest(cols = steps) 

df<-df %>%
    left_join(., sexmap)

df<-df %>%
    mutate(cos_ta = cos(ta_), 
        log_sl = log(sl_)) %>%
    mutate(season=lubridate::semester(t1_)) %>%
    mutate(season=as.factor(case_when(
        season ==2 ~ "Winter",
        season == 1 ~ "Summer"))) 

saveRDS(df, "Outputs/ModelDataframe.RDS")