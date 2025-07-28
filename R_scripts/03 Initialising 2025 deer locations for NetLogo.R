library(terra)
library(dplyr)
setwd("~/")

# Load shapefile + reproject
shp <- vect("Corsica deer/Data/current_deer_pops/aires repartitions cerf 2025.qgz.shp")
shp <- project(shp, "EPSG:4258")
writeVector(shp, "Corsica deer/Data/current_deer_pops/reproj aires repartitions cerf 2025.qgz.shp")

# Load reprojected shp
shp <- vect("Corsica deer/Data/current_deer_pops/reproj aires repartitions cerf 2025.qgz.shp")

# Reproject polygons to EPSG:2154 (meters) for sampling
shp_proj <- project(shp, "EPSG:2154")

# Number of repetitions per case
n_reps <- 50

generate_points_set <- function(polygon, deer_count, polygon_id, sample_id, level) {
  if (deer_count < 1) return(NULL)  # Return NULL if no points needed
  
  area <- expanse(polygon, unit = "m")  # Calculate polygon area in square meters
  grid_res <- sqrt(area / deer_count)   # Estimate grid resolution for even spacing
  
  grid <- rast(ext(polygon), resolution = grid_res, crs = crs(polygon))  # Create empty raster grid over polygon extent
  pts <- vect(xyFromCell(grid, 1:ncell(grid)), type = "points", crs = crs(polygon))  # Convert raster cells to points
  inside_pts <- pts[polygon]  # Keep only points that fall inside the polygon
  
  if (nrow(inside_pts) == 0) return(NULL)  # Return NULL if no points inside polygon
  
  coords <- crds(inside_pts)  # Extract coordinates of points inside polygon
  jitter_amt <- grid_res * 0.5  # Set jitter amount as 25% of grid resolution
  coords_jittered <- coords + matrix(runif(nrow(coords) * 2, -jitter_amt, jitter_amt), ncol = 2)  # Add random jitter to spread points
  
  pts_df <- as.data.frame(coords_jittered)  # Convert jittered coordinates to data.frame
  colnames(pts_df) <- c("x", "y")  # Name coordinate columns
  
  if (nrow(pts_df) > deer_count) {
    pts_df <- pts_df[sample(1:nrow(pts_df), deer_count), ]  # Randomly sample desired number of points if too many
  }
  
  pts_df$polygon_id <- polygon$Nom  # Add polygon identifier
  pts_df$sample_id <- sample_id     # Add sample/repetition identifier
  pts_df$pop_level <- level         # Add population level label
  
  return(pts_df)  # Return final dataframe of points
}


# Now, run the function on the shpfiles
set.seed(1)
for (rep_id in 1:n_reps) {
  all_min <- list()
  all_max <- list()
  
  for (i in 1:nrow(shp_proj)) {
    polygon <- shp_proj[i, ]
    
    min_pts <- generate_points_set(polygon, polygon$min_pop, i, rep_id, "min")
    max_pts <- generate_points_set(polygon, polygon$max_pop, i, rep_id, "max")
    
    all_min <- append(all_min, list(min_pts))
    all_max <- append(all_max, list(max_pts))
  }
  
  df_min <- bind_rows(all_min)
  df_max <- bind_rows(all_max)
  
  # If points exist, convert to spatVector in EPSG:2154 and reproject to EPSG:4258
  if (!is.null(df_min) && nrow(df_min) > 0) {
    pts_min <- vect(df_min, geom = c("x", "y"), crs = "EPSG:2154")
    pts_min <- project(pts_min, "EPSG:4258")
    writeVector(pts_min, sprintf("Corsica deer/corsica_deer_ABM/Modelling/NetLogo/Model 7 - separate validation and prediction/2025_initial_locations/deer_initial_locations_rep%d_min.shp", rep_id), overwrite = TRUE)
  }
  
  if (!is.null(df_max) && nrow(df_max) > 0) {
    pts_max <- vect(df_max, geom = c("x", "y"), crs = "EPSG:2154")
    pts_max <- project(pts_max, "EPSG:4258")
    writeVector(pts_max, sprintf("Corsica deer/corsica_deer_ABM/Modelling/NetLogo/Model 7 - separate validation and prediction/2025_initial_locations/deer_initial_locations_rep%d_max.shp", rep_id), overwrite = TRUE)
  }
}



## Checks ----------------

# Load one of your generated shapefiles
pts <- vect("Corsica deer/corsica_deer_ABM/Modelling/NetLogo/Model 7 - separate validation and prediction/2025_initial_locations/deer_initial_locations_rep1_max.shp")
crs(pts)

# Plot the polygons (in EPSG:4258)
plot(shp, col = "lightgreen", main = "Deer Points over Polygons - rep 1 min")
crs(shp)
# Add points on top
plot(pts, add = TRUE, col = "blue", pch = 20, cex = 0.1)
count <- values(pts)
count %>% group_by(count$polygon_id) %>% summarise(count = n())
#max_samples <- subset(deer_all, pop_level == "max")
#min_samples <- subset(deer_all, pop_level == "min")
#max_samples %>% group_by(polygon_id) %>% summarise(number = n()/50)
#min_samples %>% group_by(polygon_id) %>% summarise(number = n()/50)