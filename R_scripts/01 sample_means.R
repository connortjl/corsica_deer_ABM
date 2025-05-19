#### Loading in data ---------------

# File list to be loaded
files <- list.files(path = "C:/Users/conno/Documents/Corsica deer/corsica_deer_ABM/Modelling/NetLogo/Model 4 - death/results_final", pattern = "measures_")

# Loading in all the measures files and joining them together
for (i in 1:length(files)) {
  if (i == 1) { 
    data <- read.csv(paste0("~/Corsica deer/corsica_deer_ABM/Modelling/NetLogo/Model 4 - death/results_final/", files[i]), header = F)
    data$sim_id <- sub("measures_", "", sub(".csv", "", files[i]))
    colnames(data) <- c("2020", "2025", "2030", "2035", "2040", "sim_id")
    row.names(data) <- c("deer", "mature_deer", "immature_deer", "visited_patches")
    
    deer <- data[1,]
    row.names(deer) <- NULL
    
    mature_deer <- data[2,]
    row.names(mature_deer) <- NULL
    
    immature_deer <- data[3,]
    row.names(immature_deer) <- NULL
    
    visited_patches <- data[4,]
    row.names(visited_patches) <- NULL
    
    
  } else {
    additional_data <- read.csv(paste0("~/Corsica deer/corsica_deer_ABM/Modelling/NetLogo/Model 4 - death/results_final/", files[i]), header = F)
    additional_data$sim_id <- sub("measures_", "", sub(".csv", "", files[i]))
    colnames(additional_data) <- c("2020", "2025", "2030", "2035", "2040", "sim_id")
    row.names(additional_data) <- c("deer", "mature_deer", "immature_deer", "visited_patches")
    
    deer <- rbind(deer, additional_data[1,])
    row.names(deer) <- NULL
    
    mature_deer <- rbind(mature_deer, additional_data[2,])
    row.names(mature_deer) <- NULL
    
    immature_deer <- rbind(immature_deer, additional_data[3,])
    row.names(immature_deer) <- NULL
    
    visited_patches <- rbind(visited_patches, additional_data[4,])
    row.names(visited_patches) <- NULL
    
  }
}



#### Bootstrapping each output - deer numbers -----------------

sample_number <- c(10, 20, 30, 40, 50, 60, 70, 80, 90, 100) # Number of simulations to be sampled (with replacement)
repeat_number <- 1000 # How many times to repeat this sampling

median_deer <- c(0)
max_deer <- c(0)
min_deer <- c(0)

median_mature <- c(0)
max_mature <- c(0)
min_mature <- c(0)

median_immature <- c(0)
max_immature <- c(0)
min_immature <- c(0)

median_patches <- c(0)
max_patches <- c(0)
min_patches <- c(0)

set.seed(1) # Setting random seed

for (s in sample_number) {

  for (r in 1:repeat_number) { # For each repeat number
  
    # Sample with replacement from the deer, mature deer, immature deer, and patch datasets
    deer_sample <- deer[sample(nrow(deer), s, replace = T), ][, 5] # samples simulations from total deer, mature deer etc dataframes, then only uses 2040
    mature_sample <- mature_deer[sample(nrow(mature_deer), s, replace = T), ][, 5]
    immature_sample <- immature_deer[sample(nrow(immature_deer), s, replace = T), ][, 5]
    patches_sample <- visited_patches[sample(nrow(visited_patches), s, replace = T), ][, 5]

      # Create the bootstrapped datasets
     if (r == 1) {
  
       # calculates the mean of those samples for total deer, mature deer etc at year 2040 (most variation expected here)
        deer_sample_means <- mean(deer_sample) 
        mature_sample_means <- mean(mature_sample)
        immature_sample_means <- mean(immature_sample)
        patches_sample_means <- mean(patches_sample)
  
     } else {
  
       # calculates the mean of that sample for total deer, mature deer etc at year 2040 (most variation expected here) and adds to sample dataframe
      deer_sample_means <- c(deer_sample_means, mean(deer_sample)) 
       mature_sample_means <- c(mature_sample_means, mean(mature_sample))
       immature_sample_means <- c(immature_sample_means, mean(immature_sample))
       patches_sample_means <- c(patches_sample_means, mean(patches_sample))
  
     }
    }

# Joinging all these sample means together
sample_means <- as.data.frame(t(rbind(deer_sample_means, mature_sample_means, immature_sample_means, patches_sample_means))) # Sticks them together

#Calculating summary statistics
median_deer <- c(median_deer, median(sample_means$deer_sample_means))
max_deer <- c(max_deer, max(sample_means$deer_sample_means))
min_deer <- c(min_deer, min(sample_means$deer_sample_means))

median_mature <- c(median_mature, median(sample_means$mature_sample_means))
max_mature <- c(max_mature, max(sample_means$mature_sample_means))
min_mature <- c(min_mature, min(sample_means$mature_sample_means))

median_immature <- c(median_immature, median(sample_means$immature_sample_means))
max_immature <- c(max_immature, max(sample_means$immature_sample_means))
min_immature <- c(min_immature, min(sample_means$immature_sample_means))

median_patches <- c(median_patches, median(sample_means$patches_sample_means))
max_patches <- c(max_patches, max(sample_means$patches_sample_means))
min_patches <- c(min_patches, min(sample_means$patches_sample_means))

}

samples <- rbind(median_deer, max_deer, min_deer, 
                 median_mature, max_mature, min_mature, 
                 median_immature, max_immature, min_immature, 
                 median_patches, max_patches, min_patches
                 )

samples <- samples[,-1]

colnames(samples) <- c("10", "20", "30", "40", "50", "60", "70", "80", "90", "100")




#### Plotting deer numbers ---------------------------------------------------------------------

deer_numbers_samples <- as.data.frame(samples[1:9,])
deer_numbers_samples <- tibble::rownames_to_column(deer_numbers_samples, "type")


library(tidyr)
deer_numbers_samples <- gather(deer_numbers_samples, number_of_samples, numbers, 2:11)
deer_numbers_samples <- deer_numbers_samples[order(deer_numbers_samples$type),]

# Split 'type' into 'stat' (mean or sd) and 'category'(deer, immature etc)
deer_numbers_samples <- separate(deer_numbers_samples, type, into = c("stat", "category"), 
                         sep = "_", extra = "merge")

# Reshape so that each row has year, category, mean and sd
deer_numbers_samples <- pivot_wider(deer_numbers_samples, names_from = stat, values_from = numbers)

deer_numbers_samples$median <- as.numeric(deer_numbers_samples$median)
deer_numbers_samples$max <- as.numeric(deer_numbers_samples$max)
deer_numbers_samples$min <- as.numeric(deer_numbers_samples$min)
deer_numbers_samples$number_of_samples <- as.numeric(deer_numbers_samples$number_of_samples)

#Medians and range
library(ggplot2)
a <- ggplot(deer_numbers_samples, aes(x = number_of_samples, y = median, color = category)) +
  geom_line(linetype = "dashed", aes(group = category)) +
  geom_point() +
  geom_errorbar(aes(ymin = min, ymax = max), width = 0.5) +
  theme_classic() +
  labs(y = "Mean number of deer\nMedian", x = "Number of simulations", title = "A") + 
  scale_color_manual(
    values = c("deer" = "black", "immature" = "blue", "mature" = "green"),
    labels = c("deer" = "Total deer", "immature" = "Immature deer", "mature" = "Mature deer"), 
    name = NULL
  ) +
  theme(legend.position = "none")

#Just ranges
b <- ggplot(deer_numbers_samples, aes(x = number_of_samples, y = max-min, color = category)) +
  geom_line(linetype = "dashed", aes(group = category)) +
  geom_point() +
  theme_classic() +
  labs(y = "Mean number of deer\nRange", x = "Number of simulations", title = "B") +
  scale_color_manual(
    values = c("deer" = "black", "immature" = "blue", "mature" = "green"),
    labels = c("deer" = "Total deer", "immature" = "Immature deer", "mature" = "Mature deer"), 
    name = NULL
  )











#### Plotting patches ---------------------------

patches_samples <- as.data.frame(samples[10:12,])
patches_samples <- tibble::rownames_to_column(patches_samples, "type")


library(tidyr)
patches_samples <- gather(patches_samples, number_of_samples, numbers, 2:11)
patches_samples <- patches_samples[order(patches_samples$type),]

# Split 'type' into 'stat' (mean or sd) and 'category'(deer, immature etc)
patches_samples <- separate(patches_samples, type, into = c("stat", "category"), 
                                 sep = "_", extra = "merge")

# Reshape so that each row has year, category, mean and sd
patches_samples <- pivot_wider(patches_samples, names_from = stat, values_from = numbers)

patches_samples$median <- as.numeric(patches_samples$median)
patches_samples$max <- as.numeric(patches_samples$max)
patches_samples$min <- as.numeric(patches_samples$min)
patches_samples$number_of_samples <- as.numeric(patches_samples$number_of_samples)

#Medians and range
library(ggplot2)
c <- ggplot(patches_samples, aes(x = number_of_samples, y = median)) +
  geom_line(linetype = "dashed", aes(group = category)) +
  geom_point() +
  geom_errorbar(aes(ymin = min, ymax = max), width = 0.5) +
  theme_classic() +
  labs(y = "Mean number of visited patches\nMedian", x = "Number of simulations", title = "C")

#Just ranges
d <- ggplot(patches_samples, aes(x = number_of_samples, y = max-min)) +
  geom_line(linetype = "dashed", aes(group = category)) +
  geom_point() +
  theme_classic() +
  labs(y = "Mean number of visited patches\nRange", x = "Number of simulations", title = "D")



#### Merging and saving plots ------------------------------------------

library(patchwork)

(a | b) / (c | d) + plot_layout(nrow = 2)

ggsave(filename = "~/Corsica deer/corsica_deer_ABM/Manuscript/Tables and figures/bootstrapping.png", 
       dpi = 1000, units = "in")

#### NOT NEEDED? Bootstrapping each output - HR sizes -----------------

library(dplyr)
library(stringr)

### Need to load sims in the same order each time
### Function to extract sim IDs
extract_id <- function(filename) {
  as.numeric(stringr::str_extract(filename, "(?<=_)\\d+(?=\\.csv$)"))
}

# File list to be loaded into R
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

# Calculating mean of mean HR and sd
mean_HR_by_sim <- t(as.data.frame(colMeans(alive_home_range_sizes[,-1], na.rm = TRUE)))
sd_HR_by_sim <- t(as.data.frame(apply(alive_home_range_sizes[,-1], na.rm = TRUE, 2, sd))) # 2 = columns
alive_HR_by_sim <- rbind(mean_HR_by_sim, sd_HR_by_sim)

# Tidying up
alive_HR_by_sim <- alive_HR_by_sim[-2,]
alive_HR_by_sim <- as.vector(alive_HR_by_sim)

## Sampling

sample_number <- 100 # Number of simulations to be sampled (with replacement)
repeat_number <- 100 # How many times to repeat this sampling

set.seed(1) # Setting random seed
HR_sample_means <- t(replicate(repeat_number, sample(alive_HR_by_sim, size = sample_number, replace = TRUE))) # Sampling from the simulated mean HRs for mean of means

row.names(sample) <- NULL # No row names

HR_sample_mean_of_means <- rowMeans(HR_sample_means) # Calculating the means of the bootstrapped HR sizes

median(HR_sample_mean_of_means) # median (could use mean)
max(HR_sample_mean_of_means) - min(HR_sample_mean_of_means) # Range of HR sizes







