library(terra)

# Setting working directory and loading outline map
outline <- vect("~/Corsica deer/corsica_deer_ABM/GIS/Administrative boundaries/corsica_outline.shp")
setwd("~/Corsica deer/corsica_deer_ABM/Modelling/NetLogo/Model 7 - separate validation and prediction/output_maps/prediction")

# Two functions for loading the raster maps: either by year or by simulation ID
load_max_asc_files_by_year <- function() {
  
  # Mapping from model years to calendar years
  year_map <- c("730" = 2026,
                "1460" = 2027,
                "2190" = 2028,
                "2922" = 2029,
                "3652" = 2030)
  
  # List all .asc files
  asc_files <- list.files(pattern = "max.*\\.asc$", full.names = TRUE)
  
  # Order so that rasters with the same [[i]] later on are from the same sim
  number_values <- sapply(asc_files, function(f) {
    fname <- basename(f)
    as.integer(sub("max_(\\d+)_.*", "\\1", fname))
  })
  asc_files <- asc_files[order(number_values)]
  
  
  # Load each file into a SpatRaster
  rasters <- lapply(asc_files, function(f) {
    r <- rast(f) # Load the raster
    r <- shift(r, dx = 0.000381, dy = 0.0002)
    names(r) <- tools::file_path_sans_ext(basename(f)) # Name the raster after the file
    r
  })
  
  # Extract year from filenames
  years <- sapply(asc_files, function(f) {
    parts <- strsplit(basename(f), "_")[[1]] # Extracts the final part of the file name, and splits by "_"
    model_year <- tools::file_path_sans_ext(parts[length(parts)]) #takes the last part 
    calendar_year <- year_map[model_year] # Converts it to a calander year
    as.integer(calendar_year) # Converts to an interger
  })
  
  # Organize rasters into a list by year
  rasters_by_year <- split(rasters, years) # Creates list where entries are grouped by calander year
  
  return(rasters_by_year) # Returns a list
}

load_min_asc_files_by_year <- function() {
  
  # Mapping from model years to calendar years
  year_map <- c("730" = 2026,
                "1460" = 2027,
                "2190" = 2028,
                "2922" = 2029,
                "3652" = 2030)
  
  # List all .asc files
  asc_files <- list.files(pattern = "min.*\\.asc$", full.names = TRUE)
  
  # Order so that rasters with the same [[i]] later on are from the same sim
  number_values <- sapply(asc_files, function(f) {
    fname <- basename(f)
    as.integer(sub("min_(\\d+)_.*", "\\1", fname))
  })
  
  asc_files <- asc_files[order(number_values)]
  # Load each file into a SpatRaster
  rasters <- lapply(asc_files, function(f) {
    r <- rast(f) # Load the raster
    r <- shift(r, dx = 0.000381, dy = 0.0002)
    names(r) <- tools::file_path_sans_ext(basename(f)) # Name the raster after the file
    r
  })
  
  # Extract year from filenames
  years <- sapply(asc_files, function(f) {
    parts <- strsplit(basename(f), "_")[[1]] # Extracts the final part of the file name, and splits by "_"
    model_year <- tools::file_path_sans_ext(parts[length(parts)]) #takes the last part 
    calendar_year <- year_map[model_year] # Converts it to a calander year
    as.integer(calendar_year) # Converts to an interger
  })
  
  # Organize rasters into a list by year
  rasters_by_year <- split(rasters, years) # Creates list where entries are grouped by calander year
  
  return(rasters_by_year) # Returns a list
}

# Function to scale all rasters in a nested list (by year)

rasters_by_year_max <- load_max_asc_files_by_year() # Loads all rasters in wd and groups by year
rasters_by_year_min <- load_min_asc_files_by_year() # Loads all rasters in wd and groups by year


# Splitting maps into N, C, S

maps_2030 <- sds(rasters_by_year_max$`2030`) # creates spatial raster dataset
mean_map_2030 <- app(maps_2030, mean) # calcs a mean map for 2040

breaks <- c(1e-10, max(values(mean_map_2030), na.rm = TRUE))
colors <- c("white", "blue")  # white for <= 0, blue for > 0

plot(mean_map_2030, breaks = breaks, col = colors, main = "All >0 values in blue")


r_bin <- classify(mean_map_2030, rbind(c(-Inf, 1e-10, NA), c(0, Inf, 1)))

# Convert binary raster to polygons
blobs <- as.polygons(r_bin, dissolve = TRUE)

# Remove NA values (just in case)
blobs <- blobs[!is.na(values(blobs)[,1]), ]
plot(blobs)

# Step 1: Disaggregate into single-part polygons
blobs_split <- disagg(blobs)

# Step 2: Calculate area of each piece
blobs_split$area <- expanse(blobs_split, unit="m")  # or unit="km"

# Step 3: View area distribution
hist(blobs_split$area, xlim = c(2e8, 2e10))

# Step 4: Keep only the largest pieces (e.g., top 3 by area)
top_blobs <- blobs_split[order(-blobs_split$area)[1:3], ]

# Plot to confirm
plot(top_blobs)
nrow(top_blobs)

# Splitting 

blob1 <- top_blobs[1, ]
blob2 <- top_blobs[2, ]
blob3 <- top_blobs[3, ]

plot(blob1)
south <- blob1

plot(blob2)
central <- blob2

plot(blob3)
north <- blob3

south <- project(south, crs(rasters_by_year_max[[1]][[1]]))
central <- project(central, crs(rasters_by_year_max[[1]][[1]]))
north <- project(north, crs(rasters_by_year_max[[1]][[1]]))


#For ease
region_blobs <- list(
 south = south,
  central = central,
  north = north
)

# Function to clip rasters by blobs
clip_rasters_by_region <- function(rasters_by_year, region_blobs) {
  
  result <- list()
  
  for (year in names(rasters_by_year)) {
    message("Processing year: ", year)
    year_rasters <- rasters_by_year[[year]]
    message("  Number of rasters in year ", year, ": ", length(year_rasters))
    year_clipped <- list()
    
    for (region_name in names(region_blobs)) {
      region <- region_blobs[[region_name]]
      
      clipped <- lapply(year_rasters, function(r) {
        r_crop <- crop(r, region)
        r_mask <- mask(r_crop, region)
        return(r_mask)
      })
      
      year_clipped[[region_name]] <- clipped
    }
    
    result[[year]] <- year_clipped
  }
  
  return(result)
}


# Run clipping for max and min rasters
clipped_max <- clip_rasters_by_region(rasters_by_year_max, region_blobs)
clipped_min <- clip_rasters_by_region(rasters_by_year_min, region_blobs)

south_rates_max <- c()
central_rates_max <- c()
north_rates_max <- c()
  
  for (i in c(1:50)) {
    south_rates_max <- c(south_rates_max, global(clipped_max$`2030`$south[[i]] > 0, fun = "sum", na.rm = T)[1,1] - global(clipped_max$`2026`$south[[i]] > 0, fun = "sum", na.rm = T)[1,1])
    central_rates_max <- c(central_rates_max, global(clipped_max$`2030`$central[[i]] > 0, fun = "sum", na.rm = T)[1,1] - global(clipped_max$`2026`$central[[i]] > 0, fun = "sum", na.rm = T)[1,1])
    north_rates_max <- c(north_rates_max, global(clipped_max$`2030`$north[[i]] > 0, fun = "sum", na.rm = T)[1,1] - global(clipped_max$`2026`$north[[i]] > 0, fun = "sum", na.rm = T)[1,1])
    
    }

south_rates_max <- (south_rates_max / 4) / 100
central_rates_max <- (central_rates_max / 4) / 100
north_rates_max <- (north_rates_max / 4) / 100

mean(south_rates_max)
max(south_rates_max)
min(south_rates_max)

mean(central_rates_max)
max(central_rates_max)
min(central_rates_max)

mean(north_rates_max)
max(north_rates_max)
min(north_rates_max)


south_rates_min <- c()
central_rates_min <- c()
north_rates_min <- c()

for (i in c(1:50)) {
  south_rates_min <- c(south_rates_min, global(clipped_min$`2030`$south[[i]] > 0, fun = "sum", na.rm = T)[1,1] - global(clipped_min$`2026`$south[[i]] > 0, fun = "sum", na.rm = T)[1,1])
  central_rates_min <- c(central_rates_min, global(clipped_min$`2030`$central[[i]] > 0, fun = "sum", na.rm = T)[1,1] - global(clipped_min$`2026`$central[[i]] > 0, fun = "sum", na.rm = T)[1,1])
  north_rates_min <- c(north_rates_min, global(clipped_min$`2030`$north[[i]] > 0, fun = "sum", na.rm = T)[1,1] - global(clipped_min$`2026`$north[[i]] > 0, fun = "sum", na.rm = T)[1,1])
  
}

south_rates_min <- (south_rates_min / 4) / 100
central_rates_min <- (central_rates_min / 4) / 100
north_rates_min <- (north_rates_min / 4) / 100

mean(south_rates_min)
max(south_rates_min)
min(south_rates_min)

mean(central_rates_min)
max(central_rates_min)
min(central_rates_min)

mean(north_rates_min)
max(north_rates_min)
min(north_rates_min)




