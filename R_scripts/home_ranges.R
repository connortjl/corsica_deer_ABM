

#model_type <- "Model 1 - basic model"
model_type <- "Model 2 - incorporating home range"

setwd(paste0("~/Corsica red deer/corsica_deer_ABM/Modelling/NetLogo/", model_type, "/Results"))


for (r in 1:100) {
  
  
  home_ranges <- read.csv(paste0("home-range-sizes_", r, ".csv"))
  
  colnames(home_ranges) <- c("ID", "size_ha")
  
  if (r == 1) {all_home_ranges <- home_ranges} else {all_home_ranges <- rbind(all_home_ranges, home_ranges)}
  
}

mean_home_range <- mean(all_home_ranges$size_ha)
sd_home_range <- sd(all_home_ranges$size_ha)


