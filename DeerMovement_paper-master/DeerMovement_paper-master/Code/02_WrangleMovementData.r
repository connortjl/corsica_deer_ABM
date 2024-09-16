###################################
# Get steps by burst for all deer
###################################

library(move2)
library(amt)
library(tidyverse)
library(sf)

#load
df<-readRDS("Outputs/RawMoveData.RDS") %>%
    mt_as_event_attribute(., "sex")

#get sex mapping - this individual wise data otherwise gets automatically removed in the amt data wrngling process
sexmap<-df%>%
    as_tibble %>%
    group_by(individual_local_identifier) %>%
    summarise(sex=first(sex)) %>%
    rename(id=individual_local_identifier)

#clean data 1) get relevant columns, 2) convert coords, 3) drop nas, 4) drop duplicate time stamps for a single animal
clean<-as_tibble(df) %>%
    select(individual_local_identifier, timestamp) %>%
    cbind(sf::st_coordinates(df)) %>%
    as_tibble %>%
    drop_na %>%
    distinct(individual_local_identifier, timestamp, .keep_all = TRUE)

# make track nested by animal id
trk<-make_track(clean, X, Y, timestamp, id=individual_local_identifier, crs=sf::st_crs(df)) %>%
    nest(data=-"id") %>%
    mutate(data = map(data, function(x) { transform_coords(x, 31467) } ))


# summarise sampling rates for each animal to estimat an appropriate resampling length
trk %>%
    mutate(steps = map(data, function(x) {summarize_sampling_rate(x)} )) %>%
    select(id, steps) %>%
    unnest(cols = steps) %>%
    print(n=999)
    
# apply resampling and convert to steps by burst
bursts<-trk %>%
    mutate(steps = map(data, function(x) {x %>% track_resample(rate = hours(12), tolerance = minutes(30)) %>% steps_by_burst() } ))

#examine plots visualising step lengths

#step length density by id
bursts |> select(id, steps) |> unnest(cols = steps) |>
  ggplot(aes(sl_, fill = factor(id))) + geom_density(alpha = 0.4)

#mean and median distance travelled per step
bursts |> select(id, steps) |> unnest(cols = steps) %>%
    group_by(id) %>%
    summarise(mean=mean(sl_), median=median(sl_)) %>%
    left_join(., sexmap) %>%
    pivot_longer(!c(id, sex), names_to="average", values_to="distance (m)") %>%
    ggplot(data=., aes(x=average, y=`distance (m)`, color=sex)) + 
        geom_boxplot()

# distances and times for bursts
burstSummary_df<-bursts |> select(id, steps) |> unnest(cols = steps) %>%
    left_join(., sexmap) %>%
    select(id, burst_, sex, sl_, dt_) %>%
    group_by(id, sex, burst_) %>%
    summarise(burstDistanceKm=sum(sl_)/1000, burstDays=as.numeric(sum(dt_))/24)

ggplot(data=burstSummary_df, aes(x=burstDistanceKm, y=id, color=sex)) + 
    geom_boxplot()
ggplot(data=burstSummary_df, aes(x=burstDays, y=id, color=sex)) + 
    geom_boxplot()

#save steps by burst
saveRDS(bursts, "Outputs/bursts.RDS")
saveRDS(sexmap, "Outputs/sexmap.RDS")