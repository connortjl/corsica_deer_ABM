#### Loading and viewing n-visit raster ####

library(terra)

# Setting working directory and loading outline map
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





#### Mean and sd maps ####

setwd("~/Corsica deer/Manuscript/Tables and figures")

library(viridis)
library(terra)

# ID max values for colouring
maps_2040 <- sds(rasters_by_year$`2040`) # creates spatial raster dataset
mean_map_2040 <- app(maps_2040, mean) # calcs a mean map for 2040
sd_map_2040 <- app(maps_2040, sd) # calcs a sd map

mean_vals <- values(mean_map_2040, na.rm = TRUE) # taking n-visit values from mean map and 1) removing NAs and 2) removing 0s
mean_vals <- mean_vals[!is.na(mean_vals) & mean_vals != 0]

sd_vals <- values(sd_map_2040, na.rm = TRUE) # same with sd
sd_vals <- sd_vals[!is.na(sd_vals) & sd_vals != 0]

lower_q_mean <- quantile(mean_vals, prob = 0.25) # lower quantile 
lower_q_sd <- quantile(sd_vals, prob = 0.25)

median_q_mean <- quantile(mean_vals, prob = 0.5) # median
median_q_sd <- quantile(sd_vals, prob = 0.5)

upper_q_mean <- quantile(mean_vals, prob = 0.75) # upper quantile
upper_q_sd <- quantile(sd_vals, prob = 0.75)

max_mean <- minmax(mean_map_2040)[2] # max values as [2] = max
max_sd <- minmax(sd_map_2040)[2]


breaks_mean <- c(0, 0.1, lower_q_mean, median_q_mean, upper_q_mean, max_mean) # setting up color breaks by quantiles
breaks_sd <- c(0, 0.1, lower_q_sd, median_q_sd, upper_q_sd, max_sd)

colours <- c("white", viridis(length(breaks_mean) - 2)) # colour scheme

mean_legend_labels <- c( # manually setting labels for mean values
  "0 visits",
  paste0("0 - ", round(lower_q_mean)),
  paste0(round(lower_q_mean), " - ", round(median_q_mean)),
  paste0(round(median_q_mean), " - ", round(upper_q_mean)),
  paste0(round(upper_q_mean), " - ", round(max_mean))
)

sd_legend_labels <- c( # setting values for sd labels
  "0 visits",
  paste0("0 - ", round(lower_q_sd)),
  paste0(round(lower_q_sd), " - ", round(median_q_sd)),
  paste0(round(median_q_sd), " - ", round(upper_q_sd)),
  paste0(round(upper_q_sd), " - ", round(max_sd))
)

# Define a plotting function
plot_maps <- function(year) {
  maps <- sds(rasters_by_year[[as.character(year)]]) # take maps for each year
  mean_map <- app(maps, mean) # calc mean
  sd_map <- app(maps, sd) # calc sd
  
  png(filename = paste0("mean_map_", year, ".png"), width = 2800, height = 2800, res = 800) # open png
  plot(mean_map, main = paste("Mean cumulative visit frequency\nDecember", year),# plot mean map
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
  
  png(filename = paste0("sd_map_", year, ".png"), width = 2800, height = 2800, res = 800)
  plot(sd_map, main = paste("Standard deviation cumulative visit frequency\nDecember", year),
       cex.main = 0.5,
       col = colours,
       range = c(0, max_sd),
       breaks = breaks_sd,
       legend = FALSE)
  plot(outline, add = TRUE)
  legend("topleft", 
         legend = sd_legend_labels, 
         fill = colours, 
         title = "Standard deviation cumulative visit frequency",
         cex = 0.35,
         bty = "n")
  dev.off()
}

# Now plot for each year
years <- c(2020, 2025, 2030, 2035, 2040) # list of years
for (year in years) {
  plot_maps(year) # run the above function and plot individaul mean and sd maps for all years
}



#### Min, med, max maps at each timepoint ------------

setwd("~/Corsica deer/Manuscript/Tables and figures")

years <- c(2020, 2025, 2030, 2035, 2040)

measure <-  "extent"   #"extent" "cumulative_visits"

for (year in years) { # For each year
  
  test_rasters <- rasters_by_year[[as.character(year)]] # for rasters from the tested year
  
  for (i in 1:length(test_rasters)) { # for the first raster
    
    if (i == 1) { min_raster <- test_rasters[[i]] } # setting min and max rasters
    if (i == 1) { max_raster <- test_rasters[[i]] }

    if (measure == "extent") { # if using the extent of the raster for min and max selection (the norm)
    
         #minimum extent 
              if ( global(test_rasters[[i]] > 0, "sum", na.rm = TRUE) < global(min_raster > 0, "sum", na.rm = TRUE) ) { # if the number of cells with values >0 is smaller than the prior max raster...
                min_raster <- test_rasters[[i]] # updates min raster
                #print("min raster updated")
               }
    
              #maximum extent
              if ( global(test_rasters[[i]] > 0, "sum", na.rm = TRUE) > global(max_raster > 0, "sum", na.rm = TRUE) ) { # if the number of cells with values >0 is larger than the prior max raster...
                max_raster <- test_rasters[[i]]  # updates max raster
                #print("max raster updated")
              }
      
    } 
    
    if (measure == "cumulative_visits") {
      
      print(max(values(test_rasters[[i]]))) # Sense check for me
      
              #minimum visits
              if ( global(test_rasters[[i]], "sum", na.rm = TRUE) < global(min_raster, "sum", na.rm = TRUE) ) { 
                min_raster <- test_rasters[[i]] 
                #print("min raster updated")
              }
      
              #maximum visits
              if ( global(test_rasters[[i]], "sum", na.rm = TRUE) > global(max_raster, "sum", na.rm = TRUE) ) { 
                max_raster <- test_rasters[[i]] 
                print(max(values(test_rasters[[i]]))) # Sense check for me
                #print("max raster updated")
              }
      
    } # alternative max min using deer cumulative visits (not being used currently)
  }
  
  assign(paste0("min_raster_", year), min_raster) # Finally, assign the max and min rasters to their own variables
  assign(paste0("max_raster_", year), max_raster)
  
}


#### plotting ###

library(viridis)

# ID max values for colouring - selecting max, min, med etc values
max_vals <- values(max_raster_2040, na.rm = TRUE)
max_vals <- max_vals[!is.na(max_vals) & max_vals != 0]

min_vals <- values(min_raster_2040, na.rm = TRUE)
min_vals <- min_vals[!is.na(min_vals) & min_vals != 0]

lower_q_max <- quantile(max_vals, prob = 0.25)
lower_q_min <- quantile(min_vals, prob = 0.25)

median_q_max <- quantile(max_vals, prob = 0.5)
median_q_min <- quantile(min_vals, prob = 0.5)

upper_q_max <- quantile(max_vals, prob = 0.75)
upper_q_min <- quantile(min_vals, prob = 0.75)

max_max <- max(values(max_raster_2040))
max_min <- max(values(min_raster_2040))


breaks_max <- c(0, 0.1, lower_q_max, median_q_max, upper_q_max, max_max) # Assgining breaks
breaks_min <- c(0, 0.1, lower_q_min, median_q_min, upper_q_min, max_min)

colours <- c("white", viridis(length(breaks_max) - 2)) # assinging colour scheme


max_legend_labels <- c( # manual label for max raster
  "0 visits",
  paste0("0 - ", round(lower_q_max)),
  paste0(round(lower_q_max), " - ", round(median_q_max)),
  paste0(round(median_q_max), " - ", round(upper_q_max)),
  paste0(round(upper_q_max), " - ", round(max_max))
)

min_legend_labels <- c( # mannual label for min raster
  "0 visits",
  paste0("0 - ", round(lower_q_min)),
  paste0(round(lower_q_min), " - ", round(median_q_min)),
  paste0(round(median_q_min), " - ", round(upper_q_min)),
  paste0(round(upper_q_min), " - ", round(max_min))
)


png(filename = "min_max_maps.png", width = 30000, height = 17500, res = 1000) # open the PNG

# Define layout: 2 rows x 6 columns (1 legend + 5 maps)
layout_matrix <- matrix(c(
  1, 2, 3, 4, 5, 6,
  7, 8, 9, 10, 11, 12
), nrow = 2, byrow = TRUE)

# Set relative widths: wider first column for legends
layout(layout_matrix, 
       widths = c(2, rep(2, 5)), 
       #heights = c(1, rep(2, 5))
)# Legend column is wider

# Remove all margins
par(mar = c(0, 0, 0, 0), oma = c(0, 0, 0, 0))



# First row: max maps
# First column: legend
plot(1, type = "n", axes = FALSE, xlab = "", ylab = "", xlim = c(0, 1), ylim = c(0, 1))
legend("center", 
       legend = max_legend_labels, 
       fill = colours, 
       title = "Cumulative visit frequency\nMax", 
       cex = 3,
       bty = "n")

# Columns 2-6: max maps for each year
for (year in years) { # for each year
  
  plot(get(paste0("max_raster_", year)), # plot the associated max raster
       main = paste(year),
       cex.main = 2.5,
       col = colours,
       range = c(0, max_max),
       breaks = breaks_max,
       legend = FALSE,
       asp = NA, 
       axes = F)
  
  plot(outline, add = TRUE) # and the outline
}

# Second row: min maps
# First column: legend
plot(1, type = "n", axes = FALSE, xlab = "", ylab = "", xlim = c(0, 1), ylim = c(0, 1)) # plot legent for min map rasters
legend("center", 
       legend = min_legend_labels, 
       fill = colours, 
       title = "Cumulative visit frequency\nMin", 
       cex = 3,
       bty = "n")

# Columns 2-6: min maps for each year
for (year in years) { # for each year

  plot(get(paste0("min_raster_", year)),#plot associated min raster
       #main = paste0(year),
       cex.main = 2.5,
       col = colours,
       range = c(0, max_min),
       breaks = breaks_min,
       legend = FALSE,
       asp = NA,
       axes = F)
  
  plot(outline, add = TRUE)
}

dev.off() # PNG off





##### Multiple maps in single PNG ----------------------------------------------------------

## CANNOT RUN without the above 'mean and sd maps' section being run - this is where the breaks are assigned
## This is mostly the same as the previous plotting procedure

png(filename = "all_maps_combined.png", width = 30000, height = 17500, res = 1000) #opens the png device

# Define layout: 2 rows x 6 columns (1 legend + 5 maps)
layout_matrix <- matrix(c(
  1, 2, 3, 4, 5, 6,
  7, 8, 9, 10, 11, 12
), nrow = 2, byrow = TRUE)

# Set relative widths: wider first column for legends
layout(layout_matrix, 
       widths = c(2, rep(2, 5)), 
       #heights = c(1, rep(2, 5))
       )# Legend column is wider

# Remove all margins
par(mar = c(0, 0, 0, 0), oma = c(0, 0, 0, 0))



# First row: mean maps
# First column: legend
plot(1, type = "n", axes = FALSE, xlab = "", ylab = "", xlim = c(0, 1), ylim = c(0, 1))
legend("center", 
       legend = mean_legend_labels, 
       fill = colours, 
       title = "Cumulative visit frequency\nMean", 
       cex = 3,
       bty = "n")

# Columns 2-6: mean maps for each year
for (year in years) {
  maps <- sds(rasters_by_year[[as.character(year)]])
  mean_map <- app(maps, mean)
  mean_map <- crop(mean_map, outline, mask = T)

  plot(mean_map,
       main = paste(year),
       cex.main = 2.5,
       col = colours,
       range = c(0, max_mean),
       breaks = breaks_mean,
       legend = FALSE,
       asp = NA, 
       axes = F)

    plot(outline, add = TRUE)
}

# Second row: SD maps
# First column: legend
plot(1, type = "n", axes = FALSE, xlab = "", ylab = "", xlim = c(0, 1), ylim = c(0, 1))
legend("center", 
       legend = sd_legend_labels, 
       fill = colours, 
       title = "Cumulative visit frequency\nStandard deviation", 
       cex = 3,
       bty = "n")

# Columns 2-6: sd maps for each year
for (year in years) {
  maps <- sds(rasters_by_year[[as.character(year)]])
  sd_map <- app(maps, sd)
  sd_map <- crop(sd_map, outline)
  sd_map <- mask(sd_map, outline)
  sd_map <- trim(sd_map)
  
  plot(sd_map, 
       #main = paste0(year),
       cex.main = 2.5,
       col = colours,
       range = c(0, max_sd),
       breaks = breaks_sd,
       legend = FALSE,
       asp = NA,
       axes = F)
  
  plot(outline, add = TRUE)
}

dev.off()




##### Change in cumulative visit frequencies --------------------------------------

library(fields)

setwd("~/Corsica deer/corsica_deer_ABM/Manuscript/Tables and figures")

a <- app(sds(rasters_by_year$`2025`), mean) - app(sds(rasters_by_year$`2020`), mean) # raster for change between 2020 and 2025
b <- app(sds(rasters_by_year$`2030`), mean) - app(sds(rasters_by_year$`2025`), mean) # 2025 and 2030 
c <- app(sds(rasters_by_year$`2035`), mean) - app(sds(rasters_by_year$`2030`), mean) # etc
d <- app(sds(rasters_by_year$`2040`), mean) - app(sds(rasters_by_year$`2035`), mean) # etc
stack <- c(a,b,c,d)

# ID max values for colouring

stack <- values(stack, na.rm = TRUE) # values for colourign
stack <- stack[!is.na(stack) & stack != 0]

lower_q <- quantile(stack, prob = 0.25) # lower quantile

median_q <- quantile(stack, prob = 0.5) # median

upper_q <- quantile(stack, prob = 0.75) # upper quantile

max <- max(stack) # max quantile


breaks <- c(0, 0.1, lower_q, median_q, upper_q, max) # breaks

colours <- c("white", viridis(length(breaks) - 2)) # colours

legend_labels <- c( # manual legend
  "0 visits",
  paste0("0 - ", round(lower_q)),
  paste0(round(lower_q), " - ", round(median_q)),
  paste0(round(median_q), " - ", round(upper_q)),
  paste0(round(upper_q), " - ", round(max))
)

# Start PNG device
png("change_between_years.png", width = 9600, height = 2800, res = 600)

# Layout: 1 row with 5 areas: legend + 4 rasters
layout(matrix(c(1, 2, 3, 4, 5), nrow = 1, byrow = TRUE))
par(mar = c(4, 2, 4, 4))  # Legend margins
plot.new()

# Plot shared color legend (leftmost panel)
legend("center", 
       legend = legend_labels, 
       fill = colours, 
       title = "Mean cumulative visit frequency\nChange between years", 
       cex = 1.5,
       bty = "n")

# 2. Plot the rasters
par(mar = c(1, 1, 2, 1))  # Reset margins for maps

plot(a, col = colours, breaks = breaks, main = "2020–2025", 
     cex.main = 1.5, xlab = "", ylab = "", legend = FALSE, 
     axes = F)
plot(outline, add = TRUE)

plot(b, col = colours, breaks = breaks, main = "2025–2030", 
     cex.main = 1.5, xlab = "", ylab = "", legend = FALSE, 
     axes = F)
plot(outline, add = TRUE)

plot(c, col = colours, breaks = breaks, main = "2030–2035", 
     cex.main = 1.5, xlab = "", ylab = "", legend = FALSE, 
     axes = F)
plot(outline, add = TRUE)

plot(d, col = colours, breaks = breaks, main = "2035–2040", 
     cex.main = 1.5, xlab = "", ylab = "", legend = FALSE, 
     axes = F)
plot(outline, add = TRUE)

dev.off()


























































