#### Loading and viewing n-visit raster ####

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

# Making individual figures

setwd("~/Corsica deer/Manuscript/Tables and figures/Prediction")

library(viridis)
library(terra)

# ID max values for colouring
maps_2030 <- sds(rasters_by_year_max$`2030`) # creates spatial raster dataset
mean_map_2030 <- app(maps_2030, mean) # calcs a mean map for 2040

mean_vals <- values(mean_map_2030, na.rm = TRUE) # taking n-visit values from mean map and 1) removing NAs and 2) removing 0s
mean_vals <- mean_vals[!is.na(mean_vals) & mean_vals != 0]

lower_q_mean <- quantile(mean_vals, prob = 0.25) # lower quantile 

median_q_mean <- quantile(mean_vals, prob = 0.5) # median

upper_q_mean <- quantile(mean_vals, prob = 0.75) # upper quantile

max_mean <- minmax(mean_map_2030)[2] # max values as [2] = max


breaks_mean <- c(0, 0.1, lower_q_mean, median_q_mean, upper_q_mean, max_mean) # setting up color breaks by quantiles

colours <- c("white", viridis(length(breaks_mean) - 2)) # colour scheme

mean_legend_labels <- c( # manually setting labels for mean values
  "0 visits",
  paste0("0 - ", round(lower_q_mean)),
  paste0(round(lower_q_mean), " - ", round(median_q_mean)),
  paste0(round(median_q_mean), " - ", round(upper_q_mean)),
  paste0(round(upper_q_mean), " - ", round(max_mean))
)


# Define a plotting function
plot_maps <- function(year) {
  maps <- sds(rasters_by_year_max[[as.character(year)]]) # take maps for each year
  mean_map <- app(maps, mean) # calc mean
  
  png(filename = paste0("max_map_", year, ".png"), width = 2800, height = 2800, res = 800) # open png
  plot(mean_map, main = paste("Mean max cumulative visit frequency ", year),# plot mean map
       cex.main = 0.5,
       col = colours, # pre-established colours
       range = c(0, max_mean), # pre-established range
       breaks = breaks_mean, # pre-established breaks
       legend = FALSE) # legend to be added manually
  plot(outline, add = TRUE) # plots outline of corsica
  legend("topleft", # Manually create legend 
         legend = mean_legend_labels, 
         fill = colours, 
         title = "Mean cumulative visit frequency", 
         cex = 0.35, 
         bty = "n")
  dev.off() # Close PNG and repeat below for associated sd
  
  maps <- sds(rasters_by_year_min[[as.character(year)]]) # take maps for each year
  mean_map <- app(maps, mean) # calc mean
  
  png(filename = paste0("min_map_", year, ".png"), width = 2800, height = 2800, res = 800)
  plot(mean_map, main = paste("Mean min cumulative visit frequency ", year),
       cex.main = 0.5,
       col = colours,
       range = c(0, max_mean),
       breaks = breaks_mean,
       legend = FALSE)
  plot(outline, add = TRUE)
  legend("topleft", 
         legend = mean_legend_labels, 
         fill = colours, 
         title = "Mean cumulative visit frequency",
         cex = 0.35,
         bty = "n")
  dev.off()
}

# Now plot for each year
years <- c(2026, 2027, 2028, 2029, 2030) # list of years
for (year in years) {
  plot_maps(year) # run the above function and plot individaul mean and sd maps for all years
}

##### Multiple maps in single PNG ----------------------------------------------------------

## CANNOT RUN without the above 'mean and sd maps' section being run - this is where the breaks are assigned
## This is mostly the same as the previous plotting procedure
## CAN add standard deviations - but don't think this adds a lot

png(filename = "all_maps_combined.png", width = 30000, height = 17500, res = 1000) #opens the png device
# png(filename = "all_maps_combined.png", width = 30000, height = 8750, res = 1000) #for when one row not incldued


# Define layout: 2 rows x 6 columns (1 legend + 5 maps)
layout_matrix <- matrix(c(
  1, 2, 3, 4, 5, 6,
  7, 8, 9, 10, 11, 12
), 
nrow = 2, byrow = TRUE)

# Set relative widths: wider first column for legends
layout(layout_matrix, 
       widths = c(2, rep(2, 5)), 
       heights = c(2, rep(2, 5))
)# Legend column is wider

# Remove all margins
par(mar = c(0, 0, 0, 0), oma = c(0, 0, 0, 0))



# First row: mean maps max
# First column: legend
plot(1, type = "n", axes = FALSE, xlab = "", ylab = "", xlim = c(0, 1), ylim = c(0, 1))
legend("center", 
       legend = mean_legend_labels, 
       fill = colours, 
       title = "Cumulative visit frequency\nMean of maximum scenarios", 
       cex = 3,
       bty = "n")

# Columns 2-6: mean maps for each year
for (year in years) {
  maps <- sds(rasters_by_year_max[[as.character(year)]])
  mean_map <- app(maps, mean)
  mean_map <- crop(mean_map, outline, mask = TRUE)
  
  plot(mean_map,
       main = paste(year),
       cex.main = 2.5,
       col = colours,
       range = c(0, max_mean),
       breaks = breaks_mean,
       legend = FALSE,
       asp = NA,
       axes = FALSE)  # Disable default axes
  
  axis(1, cex.axis = 2.5)  # bottom axis
  axis(2, cex.axis = 2.5)  # left axis
  box()
  plot(outline, add = TRUE)
}

# First row: mean maps min
# First column: legend
plot(1, type = "n", axes = FALSE, xlab = "", ylab = "", xlim = c(0, 1), ylim = c(0, 1))
legend("center", 
       legend = mean_legend_labels, 
       fill = colours, 
       title = "Cumulative visit frequency\nMean of minimum scenarios", 
       cex = 3,
       bty = "n")

# Columns 2-6: mean maps for each year
for (year in years) {
  maps <- sds(rasters_by_year_min[[as.character(year)]])
  mean_map <- app(maps, mean)
  mean_map <- crop(mean_map, outline, mask = TRUE)
  
  plot(mean_map,
       main = paste(year),
       cex.main = 2.5,
       col = colours,
       range = c(0, max_mean),
       breaks = breaks_mean,
       legend = FALSE,
       asp = NA,
       axes = FALSE)
  
  axis(1, cex.axis = 2.5)
  axis(2, cex.axis = 2.5)
  box()
  plot(outline, add = TRUE)
}

dev.off()




