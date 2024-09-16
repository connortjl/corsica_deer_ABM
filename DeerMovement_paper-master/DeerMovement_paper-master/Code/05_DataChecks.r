
#######################
# some basic plots to check that the model makes sense and extraction of a few key values
#####################

library(tidyverse)
library(tidyterra)
library(terra)

#load
df<-readRDS("Outputs/ModelDataframe.RDS")
r<-terra::rast("Outputs/CombinedRaster.tif")

# visualise deer areas
points<-df %>% select(id, x1_, y1_) %>% rename(lat=y1_, lon=x1_) %>% tidyterra::as_spatvector()
crs(points)<-"EPSG:31467"
hulls<-convHull(points, by="id")
deerMap<- ggplot() +
    geom_spatraster(data=crop(r, ext(hulls)), aes(fill=landcover))+
    geom_spatvector(data= hulls, fill="transparent")
ggsave("Figures/DeerLandUse.pdf", deerMap)

#comapre deer habitat use to that of randomised deer
LandClassUsePlot<-df %>% select(id, case_, landcover) %>%
    group_by(id, case_, landcover) %>%
    summarise(n=n()) %>%
    ungroup() %>%
    pivot_wider(names_from=case_, values_from=n) %>%
    mutate(useRate=`TRUE`/`FALSE`) %>%
    ggplot(data=.)+
        geom_boxplot(aes(x=landcover, y=useRate))
ggsave("Figures/LandClassUseRate.pdf", LandClassUsePlot)
#check nas in winter females

df %>% names
df %>% select(sex, season,sl_) %>%  summary

df %>%
    ggplot()+
        geom_boxplot(aes(x=log(sl_), y=season, color=sex))

#check project length
interval(first(df$t1_), last(df$t2_)) /years(1)
#check max step length
max(df$sl_)


