# Validation and evaluation

# Home range sizes - alive deer ---------------------------------

library(dplyr)
library(stringr)

### Function to extract sim IDs - wanted to ensure they were loaded in the same order each time (but don't think that's important)
extract_id <- function(filename) {
  as.numeric(stringr::str_extract(filename, "(?<=_)\\d+(?=\\.csv$)"))
}

files <- list.files(path = "~/Corsica deer/corsica_deer_ABM/Modelling/NetLogo/Model 7 - separate validation and prediction/results/evaluation/", 
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
colnames(alive_home_range_sizes) <- c("deer_id", paste0("sim_", 1:length(files)))

# Calculating mean and sd HR sizes
mean_HR_by_sim <- t(as.data.frame(colMeans(alive_home_range_sizes[,-1], na.rm = TRUE))) # mean sim values, removing the first col as it's a deer ID col which isn't needed
sd_HR_by_sim <- t(as.data.frame(apply(alive_home_range_sizes[,-1], na.rm = TRUE, 2, sd))) # 2 = columns; sd of HR sizes within sims
alive_HR_by_sim <- rbind(mean_HR_by_sim, sd_HR_by_sim) # making summary df: cols = different sims, rows = mean and sd of sims

# Resetting col and row names
colnames(alive_HR_by_sim) <- c(paste0("sim_", 1:length(files)))
row.names(alive_HR_by_sim) <- c("mean_HR_size_ha", "sd_HR_size_ha")

#overall mean, max, min of the mean HR sizes of sims
summary(alive_HR_by_sim[1,]) 

# Same for sd
summary(alive_HR_by_sim[2,])





# Home range sizes - dead deer ---------------------------------

library(dplyr)
library(stringr)

### Function to extract sim IDs - wanted to ensure they were loaded in the same order each time (but don't think that's important)
extract_id <- function(filename) {
  as.numeric(stringr::str_extract(filename, "(?<=_)\\d+(?=\\.csv$)"))
}

files <- list.files(path = "~/Corsica deer/corsica_deer_ABM/Modelling/NetLogo/Model 7 - separate validation and prediction/results/evaluation", 
                    pattern = "home-range-sizes_dead", full.names = TRUE)

# Sort files by extracted deer ID
files <- files[order(sapply(basename(files), extract_id))]

dead_home_range_sizes <- NULL
empty_files <- character()

for (i in seq_along(files)) {
  hr_sizes <- tryCatch({
    df <- read.csv(files[i], header = FALSE, stringsAsFactors = FALSE)
  
    # Extract second row and transpose to a column
    hr <- as.data.frame(t(df[2, , drop = FALSE]))
    colnames(hr) <- paste0("sim_", i)
    hr$V1 <- seq_len(nrow(hr))  # create index for joining
    hr
  }, error = function(e) {
    empty_files <<- c(empty_files, files[i])
    # Replace with a column of NAs (you can pick a default length, say max 0 at first)
    hr <- data.frame(V1 = integer(0), value = numeric(0))
    setNames(hr, c("V1", paste0("file_", i)))
  })
  
  if (is.null(dead_home_range_sizes)) {
    dead_home_range_sizes <- hr_sizes
  } else {
    dead_home_range_sizes <- full_join(dead_home_range_sizes, hr_sizes, by = "V1")
  }
}

print(empty_files)

dead_home_range_sizes <- select(dead_home_range_sizes, -V1)


#Rename columns
colnames(dead_home_range_sizes) <- c(paste0("sim_", 1:length(files)))

# Calculating mean and sd HR sizes
mean_HR_by_sim <- t(as.data.frame(colMeans(dead_home_range_sizes, na.rm = TRUE))) # mean sim values, removing the first col as it's a deer ID col which isn't needed
sd_HR_by_sim <- t(as.data.frame(apply(dead_home_range_sizes, na.rm = TRUE, 2, sd))) # 2 = columns; sd of HR sizes within sims
dead_HR_by_sim <- rbind(mean_HR_by_sim, sd_HR_by_sim) # making summary df: cols = different sims, rows = mean and sd of sims

# Resetting col and row names
colnames(dead_HR_by_sim) <- c(paste0("sim_", 1:length(files)))
row.names(dead_HR_by_sim) <- c("mean_HR_size_ha", "sd_HR_size_ha")

#overall mean, max, min of the mean HR sizes of sims
summary(dead_HR_by_sim[1,]) 

# Same for sd
summary(dead_HR_by_sim[2,])


### Death rates ---------------------------------

alive_home_range_sizes <- select(alive_home_range_sizes, -deer_id)
dead_home_range_sizes <- select(dead_home_range_sizes, -deer_id)

survival_rates <- c()

for (i in 1:ncol(alive_home_range_sizes)) {
  
  rate <- sum(complete.cases(alive_home_range_sizes[, i])) / 
    (sum(complete.cases(alive_home_range_sizes[, i])) + sum(complete.cases(dead_home_range_sizes[, i])))
  
  survival_rates <- c(survival_rates, rate)
  
}


start_date <- as.Date("2015-12-16")
end_date <- as.Date("2020-01-09")

years_between <- as.numeric(difftime(end_date, start_date, units = "days")) / 365.25
survival_rates <- survival_rates^(1/years_between)

summary(survival_rates) # But not annual


##### Mother - offspring HR sizes ---------------

# Set working directory
setwd("~/Corsica deer/corsica_deer_ABM/Modelling/NetLogo/Model 7 - separate validation and prediction/results/evaluation")

# List relevant files
files <- list.files(pattern = "mother_", full.names = TRUE)

# Preload all data to avoid reading files multiple times
data_list <- lapply(files, function(f) t(as.matrix(read.csv(f, header = FALSE))))

# Find max length across all files
max_length <- max(sapply(data_list, nrow))

# Pad each dataset to the max_length and combine with cbind
padded_data <- lapply(data_list, function(mat) { # pad the length of the shorter simulations with NAs
  length(mat) <- max_length
  return(mat) # Ensures to return back the modified object
})
mother_offspring_HR <- do.call(cbind, padded_data) # cbind list
mother_offspring_HR <- mother_offspring_HR * 100 # Convert to m from 100m

# Name columns
colnames(mother_offspring_HR) <- paste0("sim_", seq_along(files))

# Compute summary statistics (mean and SD per column)
mother_offspring_HR_summary <- rbind(
  colMeans(mother_offspring_HR, na.rm = TRUE),
  apply(mother_offspring_HR, 2, sd, na.rm = TRUE)
)

# Tidying it up
mother_offspring_HR_summary <- t(mother_offspring_HR_summary)
colnames(mother_offspring_HR_summary) <- c("mean_mother_offspring_HR_distances", "sd_mother_offspring_HR_distances")
summary(mother_offspring_HR_summary)

matured_offspring <- colSums(!is.na(mother_offspring_HR))
summary(matured_offspring)

# Number of mature offspring


## Population dynamics ---------------------------

# File list
files <- list.files(path = "C:/Users/conno/Documents/Corsica deer/corsica_deer_ABM/Modelling/NetLogo/Model 7 - separate validation and prediction/results/evaluation", 
                    pattern = "measures_") # 'measures_SIMID' has rows of total deer, total mature deer, total immature deer, and no. of explored patches at years 2020-2040 (cols)

#Loading these files and joining them up
for (i in 1:length(files)) { # For each file
  if (i == 1) { # Either initialise a dataframe
    data <- read.csv(paste0("~/Corsica deer/corsica_deer_ABM/Modelling/NetLogo/Model 7 - separate validation and prediction/results/evaluation/", files[i]), header = F)
    data$sim_id <- sub("measures_", "", sub(".csv", "", files[i]))
    colnames(data) <- c("9th Jan 2020", "sim_id")
    row.names(data) <- c("deer", "mature_deer", "immature_deer", "visited_patches")
    
    deer <- data[1,] # Initialising the four dataframes
    mature_deer <- data[2,]
    immature_deer <- data[3,]
    visited_patches <- data[4,]
    
  } else { # Or rbind to the dataframe already existing (if not the first loaded measures_ file)
    additional_data <- read.csv(paste0("~/Corsica deer/corsica_deer_ABM/Modelling/NetLogo/Model 7 - separate validation and prediction/results/evaluation/", files[i]), header = F)
    additional_data$sim_id <- sub("measures_", "", sub(".csv", "", files[i]))
    colnames(additional_data) <- c("9th Jan 2020", "sim_id")
    row.names(additional_data) <- c("deer", "mature_deer", "immature_deer", "visited_patches")
    
    deer <- rbind(deer, additional_data[1,]) # rbinding from simulations
    mature_deer <- rbind(mature_deer, additional_data[2,])
    immature_deer <- rbind(immature_deer, additional_data[3,])
    visited_patches <- rbind(visited_patches, additional_data[4,])
    
  }
}


### Calculating mean and sd across sims for each measure (deer population, patches, mature:immature ratio etc)
# Estimating mean total deer number of simulations
summary(deer[,1])
summary(mature_deer[,1])
summary(immature_deer[,1])

# Estimating mean immature:mature deer ratio
# Need to match each years mature and immature deer
sims <- deer[,2] # list of sim IDs

#Exports a df of sims (rows), years (cols) containing the ratio of immature:mature
for (i in 1:length(sims)) { # for each of these sim IDs
  
  r <- subset(immature_deer, sim_id == sims[i])[,-2] / subset(mature_deer, sim_id == sims[i])[,-2] # Calculate the ratio of immature:mature for each simulation ID
  row.names(r) <- NULL # resets row names
  if (i == 1) {ratios <- r} else {ratios <- rbind(ratios, r)} # 
  
}

# Estimating immature:mature ratio across sims - same as above
summary(ratios) # column means for each year (col) across sims (rows)


# Estimating mean visited patches of simulations - same as above
summary(visited_patches[,-2])



# Summarising all of these into one df
summary <- rbind(deer_summary, mature_deer_summary, immature_deer_summary, ratio_summary, visited_patches_summary)
#summary <- round(summary, 2) # Optional rounding so it reads easier
#summary <- as.data.frame(format(summary, scientific = FALSE)) # removing sci notation so it reads easier
summary <- as.data.frame(summary)

# Tidying up rownames for final df
library(tibble)
summary <- rownames_to_column(summary, "type")

# FINAL DATA ------------------
summary(alive_HR_by_sim[1,])
summary(dead_HR_by_sim[1,])
summary(survival_rates)
summary(mother_offspring_HR_summary[,1])
