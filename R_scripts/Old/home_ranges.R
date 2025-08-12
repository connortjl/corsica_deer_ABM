
# Home range sizes

#model_type <- "Model 1 - basic model"
#model_type <- "Model 2 - incorporating home range"
model_type <- "Model 3 - breeding"

setwd(paste0("~/Corsica deer/corsica_deer_ABM/Modelling/NetLogo/", model_type, "/Results"))


for (r in 1:100) {
  
  skip <- FALSE
  
  tryCatch(home_ranges <- read.csv(paste0("home-range-sizes_", r, ".csv")), error = function(skip) {skip <<- TRUE}) 
  
  if (skip == FALSE) {
    home_ranges$sim_number <- r
    colnames(home_ranges) <- c("ID", "size_ha", "Simulation_number")
    if (r == 2) { # REMEMBER TO CHANGE THIS TO THE SMALLEST R VALUE WITH A MAP! 
      all_home_ranges <- home_ranges
    } else {
        all_home_ranges <- rbind(all_home_ranges, home_ranges)
    }
  }

  if (skip == TRUE) {
     skip <<- FALSE
     } 
}

mean(all_home_ranges$size_ha)
sd(all_home_ranges$size_ha)


