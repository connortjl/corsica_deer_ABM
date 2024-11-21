
# Loading and viewing n-visit raster

library(terra)
library(raster)

#model_type <- "Model 1 - basic model"
#model_type <- "Model 2 - incorporating home range"
model_type <- "Model 3 - breeding"

outline <- vect("~/Corsica deer/corsica_deer_ABM/GIS/Administrative boundaries/corsica_outline.shp")
  
setwd(paste0("~/Corsica deer/corsica_deer_ABM/Modelling/NetLogo/", model_type, "/output_maps"))

rm(mean_raster)  
rm(raster)

  for (r in 1:100) {
    
    skip <- FALSE
    
    tryCatch(raster <- rast(paste0("n-visits_", r, ".asc")), error = function(skip) {skip <<- TRUE})
    
    if (skip == FALSE) {
      if (r == 2) { # REMEMBER TO CHANGE THIS TO THE SMALLEST R VALUE WITH A MAP!
        mean_raster <- raster
      } else {
          mean_raster <- c(mean_raster, raster)
          }
    }
    if (skip == TRUE) {skip <<- FALSE} 
    
  }
  
  mean_raster <- app(mean_raster, mean)

  plot(mean_raster)
  plot(outline, add = T)
  
  
  