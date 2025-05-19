library(ggplot2)

##### Number and explored patches ---------------------------

# File list
files <- list.files(path = "C:/Users/conno/Documents/Corsica deer/corsica_deer_ABM/Modelling/NetLogo/Model 4 - death/results_final", pattern = "measures_")

#Loading these files and joining them up
for (i in 1:length(files)) {
  if (i == 1) { 
    data <- read.csv(paste0("~/Corsica deer/corsica_deer_ABM/Modelling/NetLogo/Model 4 - death/results_final/", files[i]), header = F)
    data$sim_id <- sub("measures_", "", sub(".csv", "", files[i]))
    colnames(data) <- c("2020", "2025", "2030", "2035", "2040", "sim_id")
    row.names(data) <- c("deer", "mature_deer", "immature_deer", "visited_patches")
    
    deer <- data[1,]
    mature_deer <- data[2,]
    immature_deer <- data[3,]
    visited_patches <- data[4,]
    
  } else {
    additional_data <- read.csv(paste0("~/Corsica deer/corsica_deer_ABM/Modelling/NetLogo/Model 4 - death/results_final/", files[i]), header = F)
    additional_data$sim_id <- sub("measures_", "", sub(".csv", "", files[i]))
    colnames(additional_data) <- c("2020", "2025", "2030", "2035", "2040", "sim_id")
    row.names(additional_data) <- c("deer", "mature_deer", "immature_deer", "visited_patches")

    deer <- rbind(deer, additional_data[1,])
    mature_deer <- rbind(mature_deer, additional_data[2,])
    immature_deer <- rbind(immature_deer, additional_data[3,])
    visited_patches <- rbind(visited_patches, additional_data[4,])
    
  }
}

# Estimating mean total deer number of simulations
deer_summary <- colMeans(deer[,-6])
deer_summary <- rbind(deer_summary, apply(deer[,-6], 2, sd))
colnames(deer_summary) <- c("2020", "2025", "2030", "2035", "2040")
row.names(deer_summary) <- c("mean_deer", "sd_deer")

# Estimating mean mature deer number of simulations
mature_deer_summary <- colMeans(mature_deer[,-6])
mature_deer_summary <- rbind(mature_deer_summary, apply(mature_deer[,-6], 2, sd))
colnames(mature_deer_summary) <- c("2020", "2025", "2030", "2035", "2040")
row.names(mature_deer_summary) <- c("mean_mature_deer", "sd_mature_deer")

# Estimating mean immature deer number of simulations
immature_deer_summary <- colMeans(immature_deer[,-6])
immature_deer_summary <- rbind(immature_deer_summary, apply(immature_deer[,-6], 2, sd))
colnames(immature_deer_summary) <- c("2020", "2025", "2030", "2035", "2040")
row.names(immature_deer_summary) <- c("mean_immature_deer", "sd_immature_deer")

# Estimating mean immature:mature deer ratio
# Need to match each years mature and immature deer
sims <- deer[,6]

for (i in 1:length(sims)) {
  
  r <- subset(immature_deer, sim_id == sims[i])[,-6] / subset(mature_deer, sim_id == sims[i])[,-6]
  row.names(r) <- NULL
  if (i == 1) {ratios <- r} else {ratios <- rbind(ratios, r)}
  
}

ratio_summary <- colMeans(ratios)
ratio_summary <- rbind(ratio_summary, apply(ratios, 2, sd))
colnames(ratio_summary) <- c("2020", "2025", "2030", "2035", "2040")
row.names(ratio_summary) <- c("mean_ratio", "sd_ratio")

# Estimating mean visited patches of simulations
visited_patches_summary <- colMeans(visited_patches[,-6])
visited_patches_summary <- rbind(visited_patches_summary, apply(visited_patches[,-6], 2, sd))
colnames(visited_patches_summary) <- c("2020", "2025", "2030", "2035", "2040")
row.names(visited_patches_summary) <- c("mean_visited_patches", "sd_visited_patches")

# Summarising all of these
summary <- rbind(deer_summary, mature_deer_summary, immature_deer_summary, ratio_summary, visited_patches_summary)
summary <- round(summary, 2)
summary <- as.data.frame(format(summary, scientific = FALSE))

# Tidying up rownames
library(tibble)
deer_numbers <- rownames_to_column(summary, "type")



# PLotting -----------------




# Reorganising the deer numbers summary data frame - need both means and sd in a format to go into ggplot
deer_numbers <- as.data.frame(deer_numbers[1:6,])
library(tidyr)
deer_numbers <- gather(deer_numbers, year, numbers, 2:6)
deer_numbers <- deer_numbers[order(deer_numbers$type),]

# Split 'type' into 'stat' (mean or sd) and 'category'(deer, immature etc)
deer_numbers <- separate(deer_numbers, type, into = c("stat", "category"), 
                         sep = "_", extra = "merge")

# Reshape so that each row has year, category, mean and sd
deer_numbers <- pivot_wider(deer_numbers, names_from = stat, values_from = numbers)

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
ratio <- rownames_to_column(ratio, "type")


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
patches <- rownames_to_column(summary, "type")

patches <- as.data.frame(patches[9:10,])

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
ggsave(filename = "~/Corsica deer/corsica_deer_ABM/Manuscript/Tables and figures/population_patch_growth.png", 
       dpi = 1000, units = "in", width = 9.36, height = 12)






##### Home range sizes -------------------------------------------

# Alive deer

library(dplyr)
library(stringr)

### Function to extract sim IDs
extract_id <- function(filename) {
  as.numeric(stringr::str_extract(filename, "(?<=_)\\d+(?=\\.csv$)"))
}

files <- list.files(path = "~/Corsica deer/corsica_deer_ABM/Modelling/NetLogo/Model 4 - death/results_final", 
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
colnames(alive_home_range_sizes) <- c("deer_id", paste0("sim_", 1:100))

# Calculating mean and sd HR sizes
mean_HR_by_sim <- t(as.data.frame(colMeans(alive_home_range_sizes[,-1], na.rm = TRUE)))
sd_HR_by_sim <- t(as.data.frame(apply(alive_home_range_sizes[,-1], na.rm = TRUE, 2, sd))) # 2 = columns
alive_HR_by_sim <- rbind(mean_HR_by_sim, sd_HR_by_sim)

#Summary data frames
colnames(alive_HR_by_sim) <- c(paste0("sim_", 1:100))
row.names(alive_HR_by_sim) <- c("mean_HR_size_ha", "sd_HR_size_ha")

mean(alive_HR_by_sim[1,]) # 2053
max(alive_HR_by_sim[1,]) # 2211
min(alive_HR_by_sim[1,]) # 1923

mean(alive_HR_by_sim[2,]) # 411
max(alive_HR_by_sim[2,]) # 512.1
min(alive_HR_by_sim[2,]) # 357.8


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


