library(ggplot2)
library(dplyr)

##### Number and explored patches ---------------------------

# File list
files <- list.files(path = "C:/Users/conno/Documents/Corsica deer/corsica_deer_ABM/Modelling/NetLogo/Model 7 - separate validation and prediction/Results/Prediction/", 
                    pattern = "max.*measures") # 'measures_SIMID' has rows of total deer, total mature deer, total immature deer, and no. of explored patches at years 2020-2040 (cols)

#Loading these files and joining them up
for (i in 1:length(files)) { # For each file
  if (i == 1) { # Either initialise a dataframe
    data <- read.csv(paste0("~/Corsica deer/corsica_deer_ABM/Modelling/NetLogo/Model 7 - separate validation and prediction/Results/prediction/", files[i]), header = F)
    data$sim_id <- sub("measures_", "", sub(".csv", "", files[i]))
    colnames(data) <- c("2026", "2027", "2028", "2029", "2030", "sim_id")
    row.names(data) <- c("deer", "mature_deer", "immature_deer", "visited_patches")
    
    deer_max <- data[1,] # Initialising the four dataframes
    mature_deer_max <- data[2,]
    immature_deer_max <- data[3,]
    visited_patches_max <- data[4,]
    
  } else { # Or rbind to the dataframe already existing (if not the first loaded measures_ file)
    additional_data <- read.csv(paste0("~/Corsica deer/corsica_deer_ABM/Modelling/NetLogo/Model 7 - separate validation and prediction/Results/prediction/", files[i]), header = F)
    additional_data$sim_id <- sub("measures_", "", sub(".csv", "", files[i]))
    colnames(additional_data) <- c("2026", "2027", "2028", "2029", "2030", "sim_id")
    row.names(additional_data) <- c("deer", "mature_deer", "immature_deer", "visited_patches")
    
    deer_max <- rbind(deer_max, additional_data[1,]) # rbinding from simulations
    mature_deer_max <- rbind(mature_deer_max, additional_data[2,])
    immature_deer_max <- rbind(immature_deer_max, additional_data[3,])
    visited_patches_max <- rbind(visited_patches_max, additional_data[4,])
    
  }
}

files <- list.files(path = "C:/Users/conno/Documents/Corsica deer/corsica_deer_ABM/Modelling/NetLogo/Model 7 - separate validation and prediction/Results/Prediction/", 
                    pattern = "min.*measures") # 'measures_SIMID' has rows of total deer, total mature deer, total immature deer, and no. of explored patches at years 2020-2040 (cols)

#Loading these files and joining them up
for (i in 1:length(files)) { # For each file
  if (i == 1) { # Either initialise a dataframe
    data <- read.csv(paste0("~/Corsica deer/corsica_deer_ABM/Modelling/NetLogo/Model 7 - separate validation and prediction/Results/Prediction/", files[i]), header = F)
    data$sim_id <- sub("measures_", "", sub(".csv", "", files[i]))
    colnames(data) <- c("2026", "2027", "2028", "2029", "2030", "sim_id")
    row.names(data) <- c("deer", "mature_deer", "immature_deer", "visited_patches")
    
    deer_min <- data[1,] # Initialising the four dataframes
    mature_deer_min <- data[2,]
    immature_deer_min <- data[3,]
    visited_patches_min <- data[4,]
    
  } else { # Or rbind to the dataframe already existing (if not the first loaded measures_ file)
    additional_data <- read.csv(paste0("~/Corsica deer/corsica_deer_ABM/Modelling/NetLogo/Model 7 - separate validation and prediction/Results/Prediction/", files[i]), header = F)
    additional_data$sim_id <- sub("measures_", "", sub(".csv", "", files[i]))
    colnames(additional_data) <- c("2026", "2027", "2028", "2029", "2030", "sim_id")
    row.names(additional_data) <- c("deer", "mature_deer", "immature_deer", "visited_patches")
    
    deer_min <- rbind(deer_min, additional_data[1,]) # rbinding from simulations
    mature_deer_min <- rbind(mature_deer_min, additional_data[2,])
    immature_deer_min <- rbind(immature_deer_min, additional_data[3,])
    visited_patches_min <- rbind(visited_patches_min, additional_data[4,])
    
  }
}

### Calculating mean and sd across sims for each measure (deer population, patches, mature:immature ratio etc)
# Estimating mean total deer number of simulations
deer_summary <- colMeans(deer_max[,-6]) # Col means of total deer each year (col) across sims (rows)
deer_summary <- rbind(deer_summary, apply(deer_max[,-6], 2, sd))
deer_summary <- rbind(deer_summary, colMeans(deer_min[,-6])) # Then calculating sd of total deer each year (col) across sims (rows) and adding to df with previously computed means
deer_summary <- rbind(deer_summary, apply(deer_min[,-6], 2, sd))

colnames(deer_summary) <- c("2026", "2027", "2028", "2029", "2030") # Renaming cols
row.names(deer_summary) <- c("mean_max_deer", "sd_max_deer", "mean_min_deer", "sd_min_deer") # renaming rows

# Estimating mean mature deer number of simulations - same as above but with mature deer
mature_deer_summary <- colMeans(mature_deer_max[,-6])
mature_deer_summary <- rbind(mature_deer_summary, apply(mature_deer_max[,-6], 2, sd))
mature_deer_summary <- rbind(mature_deer_summary, colMeans(mature_deer_min[,-6]))
mature_deer_summary <- rbind(mature_deer_summary, apply(mature_deer_min[,-6], 2, sd))

colnames(mature_deer_summary) <- c("2026", "2027", "2028", "2029", "2030")
row.names(mature_deer_summary) <- c("mean_max_mature_deer", "sd_max_mature_deer", "mean_min_mature_deer", "sd_min_mature_deer") # renaming rows

# Estimating mean immature deer number of simulations - same as above but with immature deer
immature_deer_summary <- colMeans(immature_deer_max[,-6])
immature_deer_summary <- rbind(immature_deer_summary, apply(immature_deer_max[,-6], 2, sd))
immature_deer_summary <- rbind(immature_deer_summary, colMeans(immature_deer_min[,-6]))
immature_deer_summary <- rbind(immature_deer_summary, apply(immature_deer_min[,-6], 2, sd))

colnames(immature_deer_summary) <- c("2026", "2027", "2028", "2029", "2030")
row.names(immature_deer_summary) <- c("mean_max_immature_deer", "sd_max_immature_deer", "mean_min_immature_deer", "sd_min_immature_deer")

# Estimating mean immature:mature deer ratio
# Need to match each years mature and immature deer
sims <- deer_max[,6] # list of sim IDs

#Exports a df of sims (rows), years (cols) containing the ratio of immature:mature
for (i in 1:length(sims)) { # for each of these sim IDs
  
  r <- subset(immature_deer_max, sim_id == sims[i])[,-6] / subset(mature_deer_max, sim_id == sims[i])[,-6] # Calculate the ratio of immature:mature for each simulation ID
  row.names(r) <- NULL # resets row names
  if (i == 1) {ratios_max <- r} else {ratios_max <- rbind(ratios_max, r)} # 
  
}

# Need to match each years mature and immature deer
sims <- deer_min[,6] # list of sim IDs

#Exports a df of sims (rows), years (cols) containing the ratio of immature:mature
for (i in 1:length(sims)) { # for each of these sim IDs
  
  r <- subset(immature_deer_min, sim_id == sims[i])[,-6] / subset(mature_deer_min, sim_id == sims[i])[,-6] # Calculate the ratio of immature:mature for each simulation ID
  row.names(r) <- NULL # resets row names
  if (i == 1) {ratios_min <- r} else {ratios_min <- rbind(ratios_min, r)} # 
  
}


# Estimating immature:mature ratio across sims - same as above
ratio_summary <- colMeans(ratios_max) # column means for each year (col) across sims (rows)
ratio_summary <- rbind(ratio_summary, apply(ratios_max, 2, sd))
ratio_summary <- rbind(ratio_summary, colMeans(ratios_min)) # column means for each year (col) across sims (rows)
ratio_summary <- rbind(ratio_summary, apply(ratios_min, 2, sd))

colnames(ratio_summary) <- c("2026", "2027", "2028", "2029", "2030")
row.names(ratio_summary) <- c("mean_max_ratio", "sd_max_ratio", "mean_min_ratio", "sd_min_ratio")

# Estimating mean visited patches of simulations - same as above
visited_patches_summary <- colMeans(visited_patches_max[,-6]) # column means for each year (col) across sims (rows)
visited_patches_summary <- rbind(visited_patches_summary, apply(visited_patches_max[,-6], 2, sd))
visited_patches_summary <- rbind(visited_patches_summary, colMeans(visited_patches_min[,-6])) # column means for each year (col) across sims (rows)
visited_patches_summary <- rbind(visited_patches_summary, apply(visited_patches_min[,-6], 2, sd))

colnames(visited_patches_summary) <- c("2026", "2027", "2028", "2029", "2030")
row.names(visited_patches_summary) <- c("mean_max_visited_patches", "sd_max_visited_patches", "mean_min_visited_patches", "sd_min_visited_patches")

# Summarising all of these into one df
summary <- rbind(deer_summary, mature_deer_summary, immature_deer_summary, ratio_summary, visited_patches_summary)
summary <- round(summary, 2) # Optional rounding so it reads easier
#summary <- as.data.frame(format(summary, scientific = FALSE)) # removing sci notation so it reads easier
summary <- as.data.frame(summary)

summary(deer_max)
summary(mature_deer_max)
summary(immature_deer_max)

summary(deer_min)
summary(mature_deer_min)
summary(immature_deer_min)

##### Growth rates  ----------------------

# MAX MEAN TOTAL GROWTH RATE
(summary[1,5] / summary[1,1]) ^ (1 / 4) # Annual max deer growth rate - 1.13
#MIN TOTAL GROWTH RATE
(summary[3,5] / summary[3,1]) ^ (1 / 4) # Annual min deer growth rate - 1.12

# Average
(((summary[1,5] / summary[1,1]) ^ (1 / 4)) + ((summary[3,5] / summary[3,1]) ^ (1 / 4))) / 2

# MAX MEAN PATCH GROWTH RATE
(summary[17,5] - summary[17,1]) / 4 # Annual patch growth rate - 16,779
# MIN PATCH GROWTH RATE
(summary[19,5] - summary[19,1]) / 4 # Annual patch growth rate - 12,938


##### Per simulation growth rates

# Maximums

growth_rates_max <- c()

for (i in 1:nrow(deer_max)) {
  growth_rates_max <- c(growth_rates_max, (deer_max[i,5] / deer_max[i,1]) ^ (1 / 4))
}

growth_rates_min <- c()

for (i in 1:nrow(deer_min)) {
  growth_rates_min <- c(growth_rates_min, (deer_min[i,5] / deer_min[i,1]) ^ (1 / 4))
}

mean(growth_rates_max) 
min(growth_rates_max)
max(growth_rates_max)

mean(growth_rates_min)
min(growth_rates_min)
max(growth_rates_min)


patch_rates_max <- c()

for (i in 1:nrow(visited_patches_max)) {
  patch_rates_max <- c(patch_rates_max, (visited_patches_max[i,5] - visited_patches_max[i,1]) / 4)
}

patch_rates_min <- c()

for (i in 1:nrow(visited_patches_min)) {
  patch_rates_min <- c(patch_rates_min, (visited_patches_min[i,5] - visited_patches_min[i,1]) / 4)
}

mean(patch_rates_max) 
min(patch_rates_max)
max(patch_rates_max)

mean(patch_rates_min)
min(patch_rates_min)
max(patch_rates_min)







##### Plotting -----------------

# Reorganising the deer numbers summary data frame - need both means and sd in a format to go into ggplot
deer_numbers <- as.data.frame(summary[1:12,])
library(tidyr)
library(tibble)
deer_numbers <- rownames_to_column(deer_numbers)
deer_numbers <- gather(deer_numbers, year, numbers, 2:6)
deer_numbers <- deer_numbers[order(deer_numbers$rowname),]

# Split 'type' into 'stat' (mean or sd) and 'category'(deer, immature etc)
deer_numbers <- separate(deer_numbers, rowname, into = c("stat", "category"), 
                         sep = "_", extra = "merge")

# Reshape so that each row has year, category, mean and sd
deer_numbers <- pivot_wider(deer_numbers, names_from = stat, values_from = numbers)

deer_numbers <- separate(deer_numbers, category, into = c("scenario", "category"), 
                         sep = "_", extra = "merge")

# Ensure values are numeric
deer_numbers$mean <- as.numeric(deer_numbers$mean)
deer_numbers$sd <- as.numeric(deer_numbers$sd)

# Plotting
(a <- ggplot(deer_numbers, aes(x = year, y = mean, col = category, linetype = scenario)) +
  geom_line(aes(group = interaction(category, scenario))) +
  geom_point() +
  geom_errorbar(aes(ymin = mean - sd, ymax = mean + sd), linetype = "solid", width = 0.2) +
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
)



# 
# # same for ratio
# 
# ratio <- as.data.frame(summary[7:8,])
# 
# 
# library(tidyr)
# ratio <- gather(ratio, year, numbers, 2:6)
# ratio <- ratio[order(ratio$type),]
# 
# # Split 'type' into 'stat' (mean or sd) and 'category'(deer, immature etc)
# ratio <- separate(ratio, type, into = c("stat", "category"), 
#                   sep = "_", extra = "merge")
# 
# # Reshape so that each row has year, category, mean and sd
# ratio <- pivot_wider(ratio, names_from = stat, values_from = numbers)
# 
# ratio$mean <- as.numeric(ratio$mean)
# ratio$sd <- as.numeric(ratio$sd)
# 
# # Plotting
# b <- ggplot(ratio, aes(x = year, y = mean)) +
#   geom_line(linetype = "dashed", aes(group = category)) +
#   geom_point() +
#   geom_errorbar(aes(ymin = mean - sd, ymax = mean + sd), width = 0.2) +
#   theme_classic() +
#   labs(y = "Young:adult ratio", x = "Year", title = "B") +
#   scale_color_manual(
#     labels = c("ratio" = "Young:adult ratio"), 
#     name = NULL
#   )
# 
# 
# 
# 

#### Same for patches visited

library(tibble)
patches <- as.data.frame(summary[17:20,])

library(tidyr)
patches <- rownames_to_column(patches)
patches <- gather(patches, year, numbers, 2:6)
patches <- patches[order(patches$rowname),]

# Split 'type' into 'stat' and 'category'
patches <- separate(patches, rowname, into = c("stat", "category"), 
                    sep = "_", extra = "merge")

# Reshape so that each row has year, category, mean and sd
patches <- pivot_wider(patches, names_from = stat, values_from = numbers)

patches$mean <- as.numeric(patches$mean)
patches$sd <- as.numeric(patches$sd)

patches <- separate(patches, category, into = c("scenario", "category"), 
                         sep = "_", extra = "merge")

# Plot
(b <- ggplot(patches, aes(x = year, y = mean, linetype = scenario)) +
  geom_line(aes(group = scenario)) +
  geom_point() +
  geom_errorbar(aes(ymin = mean - sd, ymax = mean + sd), linetype = "solid", width = 0.2) +
  theme_classic() +
  labs(y = "Number of visited patches", x = "Year", title = "C") + 
    theme(
      legend.position = "inside",
      legend.position.inside = c(0.01, 0.99),
      legend.justification = c(0, 1)
    )
)
library(patchwork)

a / b
ggsave(filename = "~/Corsica deer/Manuscript/Tables and figures/prediction/population_patch_growth.png", 
       dpi = 1000, units = "in", width = 9.36, height = 8)



