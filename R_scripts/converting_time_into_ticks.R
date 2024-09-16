
library(lubridate)
library(terra)
library(dplyr)

setwd("~/Corsica red deer")

release_points <- vect("corsica_deer_ABM/Modelling/NetLogo/releasePoints/releasePoints.shp")
#plot(release_points)


values <- values(release_points)
values$time <- as.numeric(values$time)
values <- mutate(values, trad_date = as.POSIXct(time, origin = "1970-01-01"))
min_time <- min(values$time)
values <- mutate(values, new_time = time - min_time)

# Converting the seconds into 'ticks' (12 hours/tick)
values <- values %>% mutate(ticks = round(new_time / 43200))
max(values$ticks)
values <- values[,5]


release_points <- vect("corsica_deer_ABM/Modelling/NetLogo/releasePoints/releasePoints.shp")
release_points$time <- values
release_points$time

# Have checked sexes with OG data
sex_deer <- c("male", "female", "female", "female", "male", "male", "female", "female", "male", "female", "female", "female", "female", "female", "female", "female", "female", "female", "female", "male", "female", "female", "female", "female", "female", "male")
release_points$sex_deer <- sex_deer
release_points$sex_deer
values(release_points)

writeVector(release_points, "corsica_deer_ABM/Modelling/NetLogo/release_sites_for_NetLogo.shp", overwrite=TRUE)



# Estimating number of ticks until start of current year

max_time <- as.numeric(as.POSIXct("2020/12/31 22:00:00"))
time_difference <- max_time - min_time
max_ticks <- time_difference / 43200
round(max_ticks) # Approx 3685 ticks takes us from the first release until 2020/12/31 22:00:00 the last day of GPS data - can change later easily if needed


