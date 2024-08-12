
# Loading and viewing n-visit raster

library(terra)
library(raster)


setwd("~/Corsica red deer")

n_visits <- rast("corsica_deer_ABM/Modelling/NetLogo/n-visits.asc")
corsica_outline <- vect("corsica_deer_ABM/GIS/Administrative boundaries/corsica_outline.shp")


plot(n_visits)
plot(corsica_outline, add = T)
