library(terra)
library(dplyr)

# Load shapefile
shp <- vect("Corsica deer/Data/current_deer_pops/aires repartitions cerf 2025.qgz.shp")

# Reproject polygons from EPSG:2154 to EPSG:4258
shp_etrs89 <- project(shp, "EPSG:4258")

# Number of repetitions per case
n_reps <- 50

# Create a function to generate points per polygon for one repetition
# Loop through repetitions, build points, and save per rep + pop_level
for (rep_id in 1:n_reps) {
  all_min <- list()
  all_max <- list()
  
  for (i in 1:nrow(shp_etrs89)) {
    polygon <- shp_etrs89[i, ]
    
    min_pts <- generate_points_set(polygon, polygon$min_pop, i, rep_id, "min")
    max_pts <- generate_points_set(polygon, polygon$max_pop, i, rep_id, "max")
    
    all_min <- append(all_min, list(min_pts))
    all_max <- append(all_max, list(max_pts))
  }
  
  # Combine all polygons for this repetition and pop_level
  df_min <- bind_rows(all_min)
  df_max <- bind_rows(all_max)
  
  # Convert to spatVector
  df_min <- vect(df_min, geom = c("x", "y"), crs = "EPSG:4258")
  df_max <- vect(df_max, geom = c("x", "y"), crs = "EPSG:4258")
  
  # Write shapefiles for this repetition
  if (!is.null(df_min) && nrow(df_min) > 0) {
    writeVector(df_min, sprintf("Corsica deer/corsica_deer_ABM/Modelling/NetLogo/Model 7 - separate validation and prediction/2025_initial_locations/deer_initial_locations_rep%d_min.shp", rep_id))
  }
  if (!is.null(df_max) && nrow(df_max) > 0) {
    writeVector(df_max, sprintf("Corsica deer/corsica_deer_ABM/Modelling/NetLogo/Model 7 - separate validation and prediction/2025_initial_locations/deer_initial_locations_rep%d_max.shp", rep_id))
  }
}




#Checks
#max_samples <- subset(deer_all, pop_level == "max")
#min_samples <- subset(deer_all, pop_level == "min")
#max_samples %>% group_by(polygon_id) %>% summarise(number = n()/50)
#min_samples %>% group_by(polygon_id) %>% summarise(number = n()/50)