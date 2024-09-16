##################################
# Get combined raster in same projection as gps data
#####################################

library(terra)
library(tidyterra)
library(tidyverse)

# load rasters from GEE
e<-rast("Data/Corsica_elevation.tif")
s<-rast("Data/Corsica_slope.tif")
lc<-as.factor(rast("Data/Corsica_landCover.tif"))
rd<-rast("Data/Corsica_roadDistance.tif")

# refactor land cover

rclmat<-as.matrix(cbind(
    1:599,
    c(  rep(1, 199), #artifical
        rep(2, 100), # agricultural
        rep(3, 20), #forest
        rep(4, 10), #scrub
        rep(5, 70), #bare
        rep(6, 100), #wetlands
        rep(7, 100) #water
)))

lc_rcl <- classify(lc, rclmat, include.lowest=TRUE)
lc_classes <- data.frame(id=1:7, landcover=c("Artificial", "Agricultural", "Forest", "Scrub", "Bare", "Wetlands", "Water"))
levels(lc_rcl) <- lc_classes

#make corsica masked raster
mask<-lc==0
r<-mask(x=c(lc_rcl, e, s, rd), mask=mask, maskvalues=1, updatevalue=NA )
r<-project(r, "EPSG:31467")

#########################
#check rasters
ggplot()+
    geom_spatraster(data=r, aes(fill=landcover))+
    theme_minimal()

ggplot()+
    geom_spatraster(data=r, aes(fill=elevation))+
    theme_minimal()


ggplot()+
    geom_spatraster(data=r, aes(fill=slope))+
    theme_minimal()

values(r$landcover) %>% table

ggplot()+
    geom_spatraster(data=r, aes(fill=distance))+
    theme_minimal()

#################
#output
terra::writeRaster(r, "Outputs/CombinedRaster.tif", overwrite=TRUE)