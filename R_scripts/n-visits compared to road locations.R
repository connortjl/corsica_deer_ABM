library(terra)
library(viridis)

## Aligning with roads

outline <- vect("~/Corsica deer/corsica_deer_ABM/GIS/Administrative boundaries/corsica_outline.shp")
setwd(paste0("~/Corsica deer/corsica_deer_ABM/Modelling/NetLogo/Model 6 - bestmodel1&dist2release/output_maps/"))


# Two functions for loading the raster maps: either by year or by simulation ID
load_asc_files_by_year <- function() {
  
  # Mapping from model years to calendar years
  year_map <- c("3654" = 2020,
                "7306" = 2025,
                "10958" = 2030,
                "14610" = 2035,
                "18264" = 2040)
  
  # List all .asc files
  asc_files <- list.files(pattern = "\\.asc$", full.names = TRUE)
  
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

rasters_by_year <- load_asc_files_by_year() # Loads all rasters in wd and groups by year



### Getting the visit map ready to plot ----------

mean_2040 <- sds(rasters_by_year$`2040`)
mean_2040 <- app(mean_2040, mean)

mean_vals <- values(mean_2040, na.rm = TRUE) # taking n-visit values from mean map and 1) removing NAs and 2) removing 0s
mean_vals <- mean_vals[!is.na(mean_vals) & mean_vals != 0]


lower_q_mean <- quantile(mean_vals, prob = 0.25) # lower quantile 

median_q_mean <- quantile(mean_vals, prob = 0.5) # median

upper_q_mean <- quantile(mean_vals, prob = 0.75) # upper quantile

max_mean <- minmax(mean_2040)[2] # max values as [2] = max


breaks_mean <- c(0, 0.1, lower_q_mean, median_q_mean, upper_q_mean, max_mean) # setting up color breaks by quantiles

colours <- c("white", viridis(length(breaks_mean) - 2)) # colour scheme

mean_legend_labels <- c( # manually setting labels for mean values
  "0 visits",
  paste0("0 - ", round(lower_q_mean)),
  paste0(round(lower_q_mean), " - ", round(median_q_mean)),
  paste0(round(median_q_mean), " - ", round(upper_q_mean)),
  paste0(round(upper_q_mean), " - ", round(max_mean))
)



### Identify roads -------------------------

roads_dist <- rast("../distance.asc")

roads <- roads_dist < 100 & roads_dist > 1e-10 # Distances are in meters, thus less than 1 cell away

# First convert the binary raster to polygons (lines will follow from edges of polygons)
roads <- as.polygons(roads, dissolve = TRUE)

# Convert polygons to lines
roads <- as.lines(roads)

### plot ---------------------
setwd("~/Corsica deer/Manuscript/Tables and figures")

png(filename = "roads_and_deer.png", width = 2000, height = 2000, res = 1000)

plot(mean_2040, # plot mean map
     cex.main = 0.5,
     col = colours, # pre-established colours
     range = c(0, max_mean), # pre-established range
     breaks = breaks_mean, # pre-established breaks
     legend = FALSE) # legend to be added manually
legend("topleft", # Manually create legend 
       legend = mean_legend_labels, 
       fill = colours, 
       title = "Mean cumulative visit frequency", 
       cex = 0.2, 
       bty = "n")
lines(roads, col = "red", lwd = 0.2)

dev.off()
