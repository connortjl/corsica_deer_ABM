

library(terra)
library(stringr)

release_sites <- vect("Corsica deer/corsica_deer_ABM/Modelling/NetLogo/release_sites_for_NetLogo.shp")
new_release_sites <- read.csv("Corsica deer/corsica_deer_ABM/Modelling/NetLogo/data corsican Deer.csv")
new_release_sites <- vect(new_release_sites, geom = c("Long", "Lat"), crs="+proj=longlat")



writeVector(new_release_sites, "Corsica deer/corsica_deer_ABM/Modelling/NetLogo/new_release_sites_for_NetLogo.shp", overwrite = T)
