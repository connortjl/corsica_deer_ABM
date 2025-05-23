
### Maps ---------------------------------------------------------------
library(terra)

setwd(paste0("~/Corsica deer/corsica_deer_ABM/Modelling/NetLogo/Model 6 - bestmodel1&dist2release/output_maps/"))
outline <- vect("~/Corsica deer/corsica_deer_ABM/GIS/Administrative boundaries/corsica_outline.shp")

files <- list.files()

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
    names(r) <- tools::file_path_sans_ext(basename(f)) # Name the raster after the file
    r
  })
  
  # Extract year from filenames
  years <- sapply(asc_files, function(f) {
    parts <- strsplit(basename(f), "_")[[1]] # 
    model_year <- tools::file_path_sans_ext(parts[length(parts)])
    calendar_year <- year_map[model_year]
    as.integer(calendar_year)
  })
  
  # Organize rasters into a list by year
  rasters_by_year <- split(rasters, years)
  
  return(rasters_by_year)
}

rasters_by_year <- load_asc_files_by_year()


plot(rasters_by_year$`2020`[[1]])
plot(outline, add = T)

plot(rasters_by_year$`2025`[[1]])
plot(outline, add = T)

plot(rasters_by_year$`2030`[[1]])
plot(outline, add = T)

plot(rasters_by_year$`2035`[[1]])
plot(outline, add = T)

plot(rasters_by_year$`2040`[[1]])
plot(outline, add = T)


### Home ranges -------------------------------------------------------
# Alive deer

library(dplyr)
library(stringr)

### Function to extract sim IDs
extract_id <- function(filename) {
  as.numeric(stringr::str_extract(filename, "(?<=_)\\d+(?=\\.csv$)"))
}

files <- list.files(path = "~/Corsica deer/corsica_deer_ABM/Modelling/NetLogo/Model 6 - bestmodel1&dist2release/Results/tests", 
                    pattern = "home-range-sizes_still", full.names = TRUE)

# Sort files by extracted deer ID
files <- files[order(sapply(basename(files), extract_id))]

# Read and merge alive deer files
for (i in seq_along(files)) {
  d <- read.csv(files[i], header = FALSE)
  if (i == 1) {
    alive_home_range_sizes <- d
  } else {
    alive_home_range_sizes <- full_join(alive_home_range_sizes, d, by = "V1")
  }
}

#Rename columns
colnames(alive_home_range_sizes) <- c("deer_id", paste0("sim_", 1:1))

# Calculating mean and sd HR sizes
mean(alive_home_range_sizes$sim_1)
sd(alive_home_range_sizes$sim_1)


#### mother-offspring HR distance----------------------------------

setwd(paste0("~/Corsica deer/corsica_deer_ABM/Modelling/NetLogo/Model 6 - bestmodel1&dist2release/Results/tests/"))

files <- list.files(path = "~/Corsica deer/corsica_deer_ABM/Modelling/NetLogo/Model 6 - bestmodel1&dist2release/Results/tests/", 
                    pattern = "mother_", full.names = TRUE)

HR_distances <- t(read.csv(files, header = F))

mean(HR_distances)
sd(HR_distances)



### Step lengths -----------------

library(data.table)

step_lengths <- as.data.frame(t(fread("~/Corsica deer/corsica_deer_ABM/Modelling/NetLogo/Model 6 - exporatory phase/Results/step_lengths_184924.csv")))

test <- subset(step_lengths, V1 <= 10)
mean(test$V1)
sd(test$V1)
max(test$V1)
plot(density(test$V1, bw = .4), xlim = c(0,10))
