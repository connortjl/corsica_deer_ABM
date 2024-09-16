
# Loading and viewing n-visit raster

library(terra)
library(raster)

#model_type <- "Model 1 - basic model"
model_type <- "Model 2 - incorporating home range"

outline <- vect("~/Corsica red deer/corsica_deer_ABM/GIS/Administrative boundaries/corsica_outline.shp")
  
setwd(paste0("~/Corsica red deer/corsica_deer_ABM/Modelling/NetLogo/", model_type, "/output_maps"))

  
  for (r in 1:100) {
    
    
    raster <- rast(paste0("n-visits_", r, ".asc"))
    
    if (r == 1) {mean_raster <- raster} else {mean_raster <- c(mean_raster, raster)}
    
  }
  
  mean_raster <- app(mean_raster, mean)

  plot(mean_raster)
  plot(outline, add = T)
  
  
  