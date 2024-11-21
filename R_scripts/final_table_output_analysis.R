# Number and explored patches

data <- read.csv(paste0("~/Corsica deer/corsica_deer_ABM/Modelling/NetLogo/", model_type, "/Results/deer_dispersal_breeding test - 100 replications-table.csv"), skip = 6)
data <- cbind(data[,1], data[,124:128])
data <- data[!duplicated(data), ]

mean(data$count.deer...all.deer)
sd(data$count.deer...all.deer)
plot(density(data$count.deer...all.deer))

mean(data$count.deer.with..mature....yes.....adult.deer)
sd(data$count.deer.with..mature....yes.....adult.deer)
plot(density(data$count.deer.with..mature....yes.....adult.deer))

mean(data$count.deer.with..mature....no.....offspring.deer)
sd(data$count.deer.with..mature....no.....offspring.deer)
plot(density(data$count.deer.with..mature....no.....offspring.deer))

mean(data$count.patches.with..n.visits...0....Occupied.patches)
sd(data$count.patches.with..n.visits...0....Occupied.patches)
plot(density(data$count.patches.with..n.visits...0....Occupied.patches))
