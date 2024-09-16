

library(terra)
library(raster)


setwd("~/Corsica red deer")

#combined_raster <- rast("GIS/CombinedRaster.tif")
#plot(combined_raster)

landcover <- rast("GIS/CombinedRaster.tif", lyrs = 1)
elevation <- rast("GIS/CombinedRaster.tif", lyrs = 2)
slope <- rast("GIS/CombinedRaster.tif", lyrs = 3)
road_dist <- rast("GIS/CombinedRaster.tif", lyrs = 4)

landcover <- project(landcover, "EPSG:4258")
elevation <- project(elevation, "EPSG:4258")
slope <- project(slope, "EPSG:4258")
road_dist <- project(road_dist, "EPSG:4258")

#landcover <- shift(landcover, dx=0, dy=-500)
#elevation <- shift(elevation, dx=0, dy=-500)
#slope <- shift(slope, dx=0, dy=-500)
#road_dist <- shift(road_dist, dx=0, dy=-500)

writeRaster(landcover, "Modelling/NetLogo/landcover_JW.asc", overwrite = T, NAflag = -1000)
writeRaster(elevation, "Modelling/NetLogo/elevation_JW.asc", overwrite = T, NAflag = -1000)
writeRaster(slope, "Modelling/NetLogo/slope_JW.asc", overwrite = T, NAflag = -1000)
writeRaster(road_dist, "Modelling/NetLogo/distance_JW.asc", overwrite = T, NAflag = -1000)
