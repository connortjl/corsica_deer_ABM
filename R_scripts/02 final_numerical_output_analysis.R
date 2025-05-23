library(ggplot2)
library(dplyr)

##### Number and explored patches ---------------------------

# File list
files <- list.files(path = "C:/Users/conno/Documents/Corsica deer/corsica_deer_ABM/Modelling/NetLogo/Model 6 - bestmodel1&dist2release/results/", 
                    pattern = "measures_") # 'measures_SIMID' has rows of total deer, total mature deer, total immature deer, and no. of explored patches at years 2020-2040 (cols)

#Loading these files and joining them up
for (i in 1:length(files)) { # For each file
  if (i == 1) { # Either initialise a dataframe
    data <- read.csv(paste0("~/Corsica deer/corsica_deer_ABM/Modelling/NetLogo/Model 6 - bestmodel1&dist2release/results/", files[i]), header = F)
    data$sim_id <- sub("measures_", "", sub(".csv", "", files[i]))
    colnames(data) <- c("2020", "2025", "2030", "2035", "2040", "sim_id")
    row.names(data) <- c("deer", "mature_deer", "immature_deer", "visited_patches")
    
    deer <- data[1,] # Initialising the four dataframes
    mature_deer <- data[2,]
    immature_deer <- data[3,]
    visited_patches <- data[4,]
    
  } else { # Or rbind to the dataframe already existing (if not the first loaded measures_ file)
    additional_data <- read.csv(paste0("~/Corsica deer/corsica_deer_ABM/Modelling/NetLogo/Model 6 - bestmodel1&dist2release/results/", files[i]), header = F)
    additional_data$sim_id <- sub("measures_", "", sub(".csv", "", files[i]))
    colnames(additional_data) <- c("2020", "2025", "2030", "2035", "2040", "sim_id")
    row.names(additional_data) <- c("deer", "mature_deer", "immature_deer", "visited_patches")

    deer <- rbind(deer, additional_data[1,]) # rbinding from simulations
    mature_deer <- rbind(mature_deer, additional_data[2,])
    immature_deer <- rbind(immature_deer, additional_data[3,])
    visited_patches <- rbind(visited_patches, additional_data[4,])
    
  }
}


### Calculating mean and sd across sims for each measure (deer population, patches, mature:immature ratio etc)
# Estimating mean total deer number of simulations
deer_summary <- colMeans(deer[,-6]) # Col means of total deer each year (col) across sims (rows)
deer_summary <- rbind(deer_summary, apply(deer[,-6], 2, sd)) # Then calculating sd of total deer each year (col) across sims (rows) and adding to df with previously computed means
colnames(deer_summary) <- c("2020", "2025", "2030", "2035", "2040") # Renaming cols
row.names(deer_summary) <- c("mean_deer", "sd_deer") # renaming rows

# Estimating mean mature deer number of simulations - same as above but with mature deer
mature_deer_summary <- colMeans(mature_deer[,-6])
mature_deer_summary <- rbind(mature_deer_summary, apply(mature_deer[,-6], 2, sd))
colnames(mature_deer_summary) <- c("2020", "2025", "2030", "2035", "2040")
row.names(mature_deer_summary) <- c("mean_mature_deer", "sd_mature_deer")

# Estimating mean immature deer number of simulations - same as above but with immature deer
immature_deer_summary <- colMeans(immature_deer[,-6])
immature_deer_summary <- rbind(immature_deer_summary, apply(immature_deer[,-6], 2, sd))
colnames(immature_deer_summary) <- c("2020", "2025", "2030", "2035", "2040")
row.names(immature_deer_summary) <- c("mean_immature_deer", "sd_immature_deer")

# Estimating mean immature:mature deer ratio
# Need to match each years mature and immature deer
sims <- deer[,6] # list of sim IDs

#Exports a df of sims (rows), years (cols) containing the ratio of immature:mature
for (i in 1:length(sims)) { # for each of these sim IDs
  
  r <- subset(immature_deer, sim_id == sims[i])[,-6] / subset(mature_deer, sim_id == sims[i])[,-6] # Calculate the ratio of immature:mature for each simulation ID
  row.names(r) <- NULL # resets row names
  if (i == 1) {ratios <- r} else {ratios <- rbind(ratios, r)} # 
  
}

# Estimating immature:mature ratio across sims - same as above
ratio_summary <- colMeans(ratios) # column means for each year (col) across sims (rows)
ratio_summary <- rbind(ratio_summary, apply(ratios, 2, sd))
colnames(ratio_summary) <- c("2020", "2025", "2030", "2035", "2040")
row.names(ratio_summary) <- c("mean_ratio", "sd_ratio")

# Estimating mean visited patches of simulations - same as above
visited_patches_summary <- colMeans(visited_patches[,-6])
visited_patches_summary <- rbind(visited_patches_summary, apply(visited_patches[,-6], 2, sd))
colnames(visited_patches_summary) <- c("2020", "2025", "2030", "2035", "2040")
row.names(visited_patches_summary) <- c("mean_visited_patches", "sd_visited_patches")

# Summarising all of these into one df
summary <- rbind(deer_summary, mature_deer_summary, immature_deer_summary, ratio_summary, visited_patches_summary)
#summary <- round(summary, 2) # Optional rounding so it reads easier
summary <- as.data.frame(format(summary, scientific = FALSE)) # removing sci notation so it reads easier

# Tidying up rownames for final df
library(tibble)
summary <- rownames_to_column(summary, "type")



##### Plotting -----------------

# Reorganising the deer numbers summary data frame - need both means and sd in a format to go into ggplot
deer_numbers <- as.data.frame(summary[1:6,])
library(tidyr)
deer_numbers <- gather(deer_numbers, year, numbers, 2:6)
deer_numbers <- deer_numbers[order(deer_numbers$type),]

# Split 'type' into 'stat' (mean or sd) and 'category'(deer, immature etc)
deer_numbers <- separate(deer_numbers, type, into = c("stat", "category"), 
                         sep = "_", extra = "merge")

# Reshape so that each row has year, category, mean and sd
deer_numbers <- pivot_wider(deer_numbers, names_from = stat, values_from = numbers)

# Ensure values are numeric
deer_numbers$mean <- as.numeric(deer_numbers$mean)
deer_numbers$sd <- as.numeric(deer_numbers$sd)

# Plotting
a <- ggplot(deer_numbers, aes(x = year, y = mean, color = category)) +
  geom_line(linetype = "dashed", aes(group = category)) +
  geom_point() +
  geom_errorbar(aes(ymin = mean - sd, ymax = mean + sd), width = 0.2) +
  theme_classic() +
  labs(y = "Number of deer", x = "Year", title = "A") +
  scale_color_manual(
    values = c("deer" = "black", "immature_deer" = "blue", "mature_deer" = "green", "ratio" = "orange"),
    labels = c("deer" = "Total deer", "immature_deer" = "Immature deer", "mature_deer" = "Mature deer", "ratio" = "Young:adult ratio"), 
    name = NULL
  ) + 
  theme(
    legend.position = "inside",
    legend.position.inside = c(0.01, 0.99),
    legend.justification = c(0, 1)
  )





# same for ratio

ratio <- as.data.frame(summary[7:8,])


library(tidyr)
ratio <- gather(ratio, year, numbers, 2:6)
ratio <- ratio[order(ratio$type),]

# Split 'type' into 'stat' (mean or sd) and 'category'(deer, immature etc)
ratio <- separate(ratio, type, into = c("stat", "category"), 
                         sep = "_", extra = "merge")

# Reshape so that each row has year, category, mean and sd
ratio <- pivot_wider(ratio, names_from = stat, values_from = numbers)

ratio$mean <- as.numeric(ratio$mean)
ratio$sd <- as.numeric(ratio$sd)

# Plotting
b <- ggplot(ratio, aes(x = year, y = mean)) +
  geom_line(linetype = "dashed", aes(group = category)) +
  geom_point() +
  geom_errorbar(aes(ymin = mean - sd, ymax = mean + sd), width = 0.2) +
  theme_classic() +
  labs(y = "Young:adult ratio", x = "Year", title = "B") +
  scale_color_manual(
    labels = c("ratio" = "Young:adult ratio"), 
    name = NULL
  )





#### Same for patches visited

library(tibble)
patches <- as.data.frame(summary[9:10,])

library(tidyr)
patches <- gather(patches, year, numbers, 2:6)
patches <- patches[order(patches$type),]

# Split 'type' into 'stat' and 'category'
patches <- separate(patches, type, into = c("stat", "category"), 
                         sep = "_", extra = "merge")

# Reshape so that each row has year, category, mean and sd
patches <- pivot_wider(patches, names_from = stat, values_from = numbers)

patches$mean <- as.numeric(patches$mean)
patches$sd <- as.numeric(patches$sd)

# Plot
c <- ggplot(patches, aes(x = year, y = mean)) +
  geom_line(linetype = "dashed", aes(group = category)) +
  geom_point() +
  geom_errorbar(aes(ymin = mean - sd, ymax = mean + sd), width = 0.2) +
  theme_classic() +
  labs(y = "Number of visited patches", x = "Year", title = "C")

library(patchwork)

a / b / c
ggsave(filename = "~/Corsica deer/Manuscript/Tables and figures/population_patch_growth.png", 
       dpi = 1000, units = "in", width = 9.36, height = 12)





##### Home range sizes -------------------------------------------

# Alive deer

library(dplyr)
library(stringr)

### Function to extract sim IDs - wanted to ensure they were loaded in the same order each time (but don't think that's important)
extract_id <- function(filename) {
  as.numeric(stringr::str_extract(filename, "(?<=_)\\d+(?=\\.csv$)"))
}

files <- list.files(path = "~/Corsica deer/corsica_deer_ABM/Modelling/NetLogo/Model 6 - bestmodel1&dist2release/results", 
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
mean(alive_HR_by_sim[1,]) # 
max(alive_HR_by_sim[1,]) # 
min(alive_HR_by_sim[1,]) # 

# Same for sd
mean(alive_HR_by_sim[2,]) # 
max(alive_HR_by_sim[2,]) # 
min(alive_HR_by_sim[2,]) # 


##### Mother - offspring HR sizes ---------------

# Set working directory
setwd("~/Corsica deer/corsica_deer_ABM/Modelling/NetLogo/Model 6 - bestmodel1&dist2release/results/")

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
##### Min, median, max situations --------------

# Summary stats
min(deer$`2040`)
mean(deer$`2040`)
median(deer$`2040`)
max(deer$`2040`)

min(mature_deer$`2040`)
mean(mature_deer$`2040`)
median(mature_deer$`2040`)
max(mature_deer$`2040`)

min(immature_deer$`2040`)
mean(immature_deer$`2040`)
median(immature_deer$`2040`)
max(immature_deer$`2040`)

min(visited_patches$`2040`)
mean(visited_patches$`2040`)
median(visited_patches$`2040`)
max(visited_patches$`2040`)

min(colMeans(alive_home_range_sizes[,-1], na.rm = T))
mean(colMeans(alive_home_range_sizes[, -1], na.rm = T))
median(colMeans(alive_home_range_sizes[,-1], na.rm = T))
max(colMeans(alive_home_range_sizes[,-1], na.rm = T))


