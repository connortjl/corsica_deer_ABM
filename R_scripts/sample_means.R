##### Loading in data ---------------

files <- list.files(path = "C:/Users/conno/Documents/Corsica deer/corsica_deer_ABM/Modelling/NetLogo/Model 4 - death/Results", pattern = "measures_")
for (i in 1:length(files)) {
  if (i == 1) { 
    data <- read.csv(paste0("~/Corsica deer/corsica_deer_ABM/Modelling/NetLogo/Model 4 - death/Results/", files[i]), header = F)
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
    additional_data <- read.csv(paste0("~/Corsica deer/corsica_deer_ABM/Modelling/NetLogo/Model 4 - death/Results/", files[i]), header = F)
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

sample_number <- 20
repeat_number <- 100


set.seed(1)
for (i in 1:repeat_number) {
  
deer_sample <- deer[sample(nrow(deer), sample_number, replace = T), ][, 5] # samples simulations from total deer, mature deer etc dataframes, then only uses 2040
mature_sample <- mature_deer[sample(nrow(mature_deer), sample_number, replace = T), ][, 5]
immature_sample <- immature_deer[sample(nrow(immature_deer), sample_number, replace = T), ][, 5]
patches_sample <- visited_patches[sample(nrow(visited_patches), sample_number, replace = T), ][, 5]

  if (i == 1) {
  
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

sample_means <- as.data.frame(t(rbind(deer_sample_means, mature_sample_means, immature_sample_means, patches_sample_means))) # Sticks them together

#Values
median(sample_means$deer_sample_means)
max(sample_means$deer_sample_means) - min(sample_means$deer_sample_means)

median(sample_means$mature_sample_means)
max(sample_means$mature_sample_means) - min(sample_means$mature_sample_means)

median(sample_means$immature_sample_means)
max(sample_means$immature_sample_means) - min(sample_means$immature_sample_means)

median(sample_means$patches_sample_means)
max(sample_means$patches_sample_means) - min(sample_means$patches_sample_means)









#### Bootstrapping each output - HR sizes -----------------

library(dplyr)
library(stringr)

### Function to extract sim IDs
extract_id <- function(filename) {
  as.numeric(stringr::str_extract(filename, "(?<=_)\\d+(?=\\.csv$)"))
}

files <- list.files(path = "~/Corsica deer/corsica_deer_ABM/Modelling/NetLogo/Model 4 - death/Results", 
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

mean_HR_by_sim <- t(as.data.frame(colMeans(alive_home_range_sizes[,-1], na.rm = TRUE)))
sd_HR_by_sim <- t(as.data.frame(apply(alive_home_range_sizes[,-1], na.rm = TRUE, 2, sd))) # 2 = columns
alive_HR_by_sim <- rbind(mean_HR_by_sim, sd_HR_by_sim)

alive_HR_by_sim <- alive_HR_by_sim[-2,]
alive_HR_by_sim <- as.vector(alive_HR_by_sim)

## Sampling

sample_number <- 20
repeat_number <- 100

set.seed(1)
HR_sample_means <- t(replicate(repeat_number, sample(alive_HR_by_sim, size = sample_number, replace = TRUE)))

row.names(sample) <- NULL

HR_sample_mean_of_means <- rowMeans(HR_sample_means)

median(HR_sample_mean_of_means)
max(HR_sample_mean_of_means) - min(HR_sample_mean_of_means)







