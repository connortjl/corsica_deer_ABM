install.packages("nlrx")
install.packages("future")
install.packages("parallel")


library(nlrx)
library(future)
library(parallel)


set.seed(1)

Sys.setenv(JAVA_HOME = "")

#download_netlogo("/data/corsica-deer/connor-lovell-pvc", "6.3.0", os = NA, extract = TRUE)

# Windows default NetLogo installation path (adjust to your needs!):
netlogopath <- file.path("/data/connor-lovell-pvc/corsica-deer/NetLogo 6.3.0")
modelpath <- file.path("/data/connor-lovell-pvc/corsica-deer/deer_dispersal_death_v6.3.nlogo")
outpath <- file.path("/data/connor-lovell-pvc/corsica-deer/Results")

nl <- nl(nlversion = "6.3.0",
         nlpath = netlogopath,
         modelpath = modelpath,
         jvmmem = 2048)



nl@experiment <- experiment(expname = "corsica-deer",
                            outpath = outpath,
                            repetition = 1,
                            tickmetrics = "false", # Metrics run at the end
                            idsetup = "setup",
                            idgo = "go",
                            runtime = 25570, # Should stop before this though, this is a fail-safe
                            stopcond = 'hpc-stop = "yes"', # Stops the simulation a day after the final map is exported in 2050
                            metrics = c("count deer", 'count deer with [mature = "yes"]', 'count deer with [mature = "no"]', 'count patches with [n-visits > 0]'),
                            #variables = list(),
                            constants = list("se-agricultural:step-length:winter:female" = 0.04976,
                                             "se-bare:step-length:summer:male" = 0.04185,
                                             "beta-slope:turning-angle" = 0.01336,
                                             "beta-wetlands:turning-angle" = -1.0E27,
                                             "se-wetlands:step-length:summer:male" = 0,
                                             "se-forest:step-length:summer:male" = 0.03607,
                                             "se-scrub:turning-angle" = 0.102,
                                             "se-artificial:step-length:summer:female" = 0,
                                             "beta-bare:step-length:summer:male" = -0.02799,
                                             "beta-bare:step-length:winter:female" = -0.0833,
                                             "beta-forest:step-length:summer:female" = 0,
                                             "se-forest:distance-to-road" = 2.881E-5,
                                             "beta-slope:summer" = -0.009514,
                                             "beta-forest:step-length" = 0.5917,
                                             "beta-forest:distance-to-road" = 2.366E-5,
                                             "se-slope:winter" = 0,
                                             "se-distance-from-release" = 0.01676,
                                             "beta-distance-to-road:turning-angle" = 5.199E-5,
                                             "beta-artificial" = 0,
                                             "beta-forest:step-length:winter:male" = -0.03215,
                                             "beta-wetlands:step-length" = -1.0E27,
                                             "beta-agricultural:step-length:summer:female" = 0,
                                             "beta-wetlands:step-length:winter:female" = -1.0E27,
                                             "pen-down?" = "false",
                                             "beta-agricultural:step-length:winter:male" = 0.1182,
                                             "se-artificial:distance-to-road" = 0,
                                             "beta-wetlands" = -1.0E27,
                                             "se-distance-to-road:summer" = 4.557E-5,
                                             "se-wetlands:step-length:winter:male" = 0,
                                             "se-wetlands:step-length:summer:female" = 0,
                                             "annual-birth-prob" = 0.65,
                                             "beta-distance-from-release" = -0.487,
                                             "beta-forest:turning-angle" = 0.1875,
                                             "beta-artificial:turning-angle" = 0,
                                             "se-forest:step-length:winter:female" = 0.01858,
                                             "se-wetlands:step-length" = 0,
                                             "se-wetlands" = 0,
                                             "beta-wetlands:step-length:winter:male" = -1.0E27,
                                             "se-bare:step-length:summer:female" = 0,
                                             "se-distance-to-road:winter" = 0,
                                             "beta-bare:turning-angle" = 0.7975,
                                             "beta-agricultural" = 0.3253,
                                             "se-artificial:step-length:winter:female" = 0.1196,
                                             "beta-agricultural:step-length" = 0.6001,
                                             "se-bare:step-length" = 0.1131,
                                             "se-slope:step-length" = 8.122E-4,
                                             "beta-forest:step-length:winter:female" = 0.00679,
                                             "se-agricultural:step-length:winter:male" = 0.08206,
                                             "beta-agricultural:turning-angle" = -0.1254,
                                             "beta-scrub:turning-angle" = 0.2917,
                                             "beta-turning-angle" = -2.262,
                                             "se-step-length" = 0.1107,
                                             "beta-agricultural:step-length:winter:female" = 0.101,
                                             "beta-distance-to-road:winter" = 0,
                                             "se-artificial:turning-angle" = 0,
                                             "beta-agricultural:step-length:summer:male" = 0.2533,
                                             "se-wetlands:turning-angle" = 0,
                                             "se-forest:step-length" = 0.1103,
                                             "se-distance-to-road" = 4.368E-5,
                                             "se-scrub:step-length:summer:male" = 0.03102,
                                             "se-scrub" = 0.1004,
                                             "beta-wetlands:distance-to-road" = -1.0E27,
                                             "se-bare:distance-to-road" = 2.92E-5,
                                             "beta-scrub:distance-to-road" = 2.56E-5,
                                             "beta-scrub" = 0.3444,
                                             "se-wetlands:step-length:winter:female" = 0,
                                             "se-artificial:step-length:winter:male" = 0.1632,
                                             "beta-distance-to-road" = -3.16E-4,
                                             "se-agricultural:turning-angle" = 0.1084,
                                             "se-artificial" = 0,
                                             "beta-artificial:step-length:summer:male" = 0.5016,
                                             "beta-scrub:step-length:summer:female" = 0,
                                             "se-slope" = 0.001808,
                                             "se-bare:step-length:winter:female" = 0.03783,
                                             "beta-wetlands:step-length:summer:male" = -1.0E27,
                                             "se-forest" = 0.09768,
                                             "beta-slope" = 0.02176,
                                             "beta-artificial:step-length:winter:female" = 0.3451,
                                             "se-agricultural:step-length" = 0.1164,
                                             "beta-scrub:step-length:summer:male" = 0.1536,
                                             "beta-scrub:step-length" = 0.4643,
                                             "se-bare:step-length:winter:male" = 0.04024,
                                             "se-distance-to-road:turning-angle" = 1.859E-6,
                                             "beta-bare" = 0.5212,
                                             "se-scrub:step-length:winter:male" = 0.03355,
                                             "se-forest:step-length:winter:male" = 0.03729,
                                             "se-agricultural:step-length:summer:male" = 0.0656,
                                             "beta-bare:step-length:winter:male" = -0.06209,
                                             "beta-distance-to-road:summer" = 1.88E-4,
                                             "se-artificial:step-length" = 0,
                                             "se-bare:turning-angle" = 0.1042,
                                             "se-slope:turning-angle" = 0.001267,
                                             "se-agricultural" = 0.1091,
                                             "beta-bare:step-length:summer:female" = 0,
                                             "beta-artificial:step-length:winter:male" = -0.1581,
                                             "se-scrub:step-length:winter:female" = 0.02468,
                                             "beta-bare:distance-to-road" = -2.992E-5,
                                             "beta-artificial:distance-to-road" = 0,
                                             "beta-slope:winter" = 0,
                                             "beta-forest" = 0.2462,
                                             "beta-step-length" = -0.3101,
                                             "se-agricultural:distance-to-road" = 3.755E-5,
                                             "beta-artificial:step-length:summer:female" = 0,
                                             "beta-scrub:step-length:winter:male" = 0.03264,
                                             "max-lifespan-years" = 14,
                                             "beta-wetlands:step-length:summer:female" = -1.0E27,
                                             "beta-artificial:step-length" = 0,
                                             "se-turning-angle" = 0.1027,
                                             "max-step-distance" = 86.5,
                                             "se-forest:turning-angle" = 0.1014,
                                             "se-artificial:step-length:summer:male" = 0.4052,
                                             "beta-scrub:step-length:winter:female" = 0.04294,
                                             "beta-bare:step-length" = 0.5453,
                                             "se-scrub:distance-to-road" = 2.9E-5,
                                             "annual-survival-prob" = 97,
                                             "se-wetlands:distance-to-road" = 0,
                                             "se-scrub:step-length" = 0.1109,
                                             "se-bare" = 0.1051,
                                             "se-forest:step-length:summer:female" = 0,
                                             "beta-forest:step-length:summer:male" = 0.101,
                                             "se-scrub:step-length:summer:female" = 0,
                                             "beta-agricultural:distance-to-road" = -1.454E-4,
                                             "se-slope:summer" = 0.002181,
                                             "beta-slope:step-length" = -0.009516, 
                                             "se-agricultural:step-length:summer:female" = 0)
                            
                            )


 
nl@simdesign <- simdesign_simple(nl, nseeds = 100)


# Evaluate nl object:
eval_variables_constants(nl)
print(nl)

# Run all simulations (loop over all siminputrows and simseeds) - parallelised 

plan(multisession, workers = 15)

results <- run_nl_all(nl)


# Attach results to nl object:
#setsim(nl, "simoutput") <- results

# Write output to outpath of experiment within nl
#write_simoutput(nl)

# Do further analysis:
#analyze_nl(nl)
