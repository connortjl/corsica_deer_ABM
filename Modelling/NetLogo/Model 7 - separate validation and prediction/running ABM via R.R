install.packages("nlrx")
install.packages("future")
install.packages("rJava")

library(nlrx)
library(future)
#library(rJava)

Sys.setenv(JAVA_HOME = "")

set.seed(1)

#If installing netlogo fresh

#netlogopath <- file.path("/data/connor-lovell-pvc/corsica-deer/Model 7/")
# Assuming this is your .tgz path:
#tgz_path <- "/data/connor-lovell-pvc/corsica-deer/Model 7/NetLogo-6.3.0-64.tgz"

# Untar to your netlogopath
#untar(tgz_path, exdir = netlogopath)

netlogopath <- file.path("/data/connor-lovell-pvc/corsica-deer/Model 7/NetLogo 6.3.0")
modelpath <- file.path("/data/connor-lovell-pvc/corsica-deer/Model 7/model 7 - separate validation and prediction - supercomputer.nlogo")
outpath <- file.path("/data/connor-lovell-pvc/corsica-deer/Model 7/")

nl <- nl(nlversion = "6.3.0",
         nlpath = netlogopath,
         modelpath = modelpath,
         jvmmem = 40960)



nl@experiment <- experiment(expname = "corsica-deer",
                            outpath = outpath,
                            repetition = 1,
                            tickmetrics = "false",
                            idsetup = "setup",
                            idgo = "go",
                            runtime = 3653,
                            #metrics = c("count deer"),
                            variables = list(
                              "scenario" = list(values = c("\"max\"", "\"min\"")),
                              "sample" = list(values = c(1:50))
                            ),
                            constants = list("se-agricultural:step-length:winter:female" = 0.0493340599672136,
                                             "se-bare:step-length:summer:male" = 0.04190524974611,
                                             "beta-slope:turning-angle" = 0.00904324706412455,
                                             "beta-wetlands:turning-angle" = -1.0E27,
                                             "se-wetlands:step-length:summer:male" = 0,
                                             "se-forest:step-length:summer:male" = 0.0353364689035707,
                                             "se-scrub:turning-angle" = 0.102978986301144,
                                             "se-artificial:step-length:summer:female" = 0,
                                             "beta-bare:step-length:summer:male" = -0.034699764413956,
                                             "beta-bare:step-length:winter:female" = -0.0871366331653598,
                                             "beta-forest:step-length:summer:female" = 0,
                                             "se-forest:distance-to-road" = 0.0355512366508593,
                                             "beta-slope:summer" = -0.0125029344149241,
                                             "beta-forest:step-length" = 0.538532805592645,
                                             "beta-forest:distance-to-road" = 0.0267846256015655,
                                             "se-slope:winter" = 0,
                                             "se-distance-from-release" = 0,
                                             "beta-distance-to-road:turning-angle" = 0.148379056270227,
                                             "beta-artificial" = 0,
                                             "beta-forest:step-length:winter:male" = 0.0192610407639364,
                                             "beta-wetlands:step-length" = -1.0E27,
                                             "beta-agricultural:step-length:summer:female" = 0,
                                             "beta-wetlands:step-length:winter:female" = -1.0E27,
                                             "pen-down?" = "false",
                                             "beta-agricultural:step-length:winter:male" = 0.0493934233556851,
                                             "se-artificial:distance-to-road" = 0,
                                             "beta-wetlands" = -1.0E27,
                                             "se-agricultural:step-length:summer:female" = 0,
                                             "se-distance-to-road:summer" = 0.0311010390550127,
                                             "se-wetlands:step-length:winter:male" = 0,
                                             "se-wetlands:step-length:summer:female" = 0,
                                             "annual-birth-prob" = 0.65,
                                             "beta-distance-from-release" = -0.5,
                                             "beta-forest:turning-angle" = -0.0262182446074219,
                                             "beta-artificial:turning-angle" = 0,
                                             "se-forest:step-length:winter:female" = 0.0182589798551276,
                                             "se-wetlands:step-length" = 0,
                                             "se-wetlands" = 0,
                                             "beta-wetlands:step-length:winter:male" = -1.0E27,
                                             "se-bare:step-length:summer:female" = 0,
                                             "se-distance-to-road:winter" = 0,
                                             "beta-bare:turning-angle" = 0.536239697394549,
                                             "beta-agricultural:step-length" = 0.568945390616945,
                                             "se-artificial:step-length:winter:female" = 0.118596633849117,
                                             "beta-agricultural" = 1.30707643302806,
                                             "se-bare:step-length" = 0.109727569566467,
                                             "se-slope:step-length" = 0.000809133311833045,
                                             "beta-forest:step-length:winter:female" = 0.0140116992653785,
                                             "se-agricultural:step-length:winter:male" = 0.0832456574391269,
                                             "beta-agricultural:turning-angle" = -0.419708823497002,
                                             "beta-scrub:turning-angle" = 0.0327472811652309,
                                             "se-step-length" = 0.107406231285947,
                                             "beta-turning-angle" = -2.78783818828574,
                                             "use" = "\"prediction\"",
                                             "beta-agricultural:step-length:winter:female" = -0.00251210564434179,
                                             "beta-distance-to-road:winter" = 0,
                                             "se-artificial:turning-angle" = 0,
                                             "beta-agricultural:step-length:summer:male" = 0.258758587040516,
                                             "se-wetlands:turning-angle" = 0,
                                             "se-forest:step-length" = 0.106778991169404,
                                             "se-distance-to-road" = 0.0368058860666508,
                                             "se-scrub:step-length:summer:male" = 0.0305614791374753,
                                             "se-scrub" = 0.224727638588186,
                                             "beta-wetlands:distance-to-road" = -1.0E27,
                                             "se-bare:distance-to-road" = 0.0402692245187032,
                                             "beta-scrub:distance-to-road" = -0.04120581757881,
                                             "beta-scrub" = 0.609738380725556,
                                             "se-wetlands:step-length:winter:female" = 0,
                                             "se-artificial:step-length:winter:male" = 0.157058170717006,
                                             "beta-distance-to-road" = 0.0135678807885984,
                                             "se-agricultural:turning-angle" = 0.108353655332371,
                                             "se-artificial" = 0,
                                             "beta-artificial:step-length:summer:male" = 0.233204332453198,
                                             "beta-scrub:step-length:summer:female" = 0,
                                             "se-slope" = 0.00183827938722221,
                                             "se-bare:step-length:winter:female" = 0.0372901624933728,
                                             "beta-wetlands:step-length:summer:male" = -1.0E27,
                                             "beta-slope" = 0.025518851504783,
                                             "se-forest" = 0.204758649001091,
                                             "beta-artificial:step-length:winter:female" = 0.253569683848898,
                                             "se-agricultural:step-length" = 0.112870405981353,
                                             "beta-scrub:step-length:summer:male" = 0.117495298879353,
                                             "beta-scrub:step-length" = 0.42893733037284,
                                             "se-bare:step-length:winter:male" = 0.0406090448357709,
                                             "se-distance-to-road:turning-angle" = 0.00655605509221779,
                                             "beta-bare" = 1.55328679940249,
                                             "se-scrub:step-length:winter:male" = 0.0334920734007395,
                                             "se-forest:step-length:winter:male" = 0.0372591325695567,
                                             "se-agricultural:step-length:summer:male" = 0.0636615555644124,
                                             "beta-bare:step-length:winter:male" = -0.0490732603869804,
                                             "beta-distance-to-road:summer" = 0.0877498936684734,
                                             "se-artificial:step-length" = 0,
                                             "se-bare:turning-angle" = 0.104711821024613,
                                             "se-slope:turning-angle" = 0.00125971722362838,
                                             "se-agricultural" = 0.231910053591412,
                                             "beta-bare:step-length:summer:female" = 0,
                                             "beta-artificial:step-length:winter:male" = -0.110619540831889,
                                             "se-scrub:step-length:winter:female" = 0.0245729205316433,
                                             "beta-bare:distance-to-road" = -0.191206900814103,
                                             "beta-artificial:distance-to-road" = 0,
                                             "beta-forest" = -0.00491848470064734,
                                             "beta-slope:winter" = 0,
                                             "beta-step-length" = -0.277981115906896,
                                             "se-agricultural:distance-to-road" = 0.0393866065041926,
                                             "beta-artificial:step-length:summer:female" = 0,
                                             "beta-scrub:step-length:winter:male" = 0.0271160497875645,
                                             "profile-tick-number" = 600,
                                             "max-lifespan-years" = 14,
                                             "beta-wetlands:step-length:summer:female" = -1.0E27,
                                             "beta-artificial:step-length" = 0,
                                             "se-turning-angle" = 0.10743227235049,
                                             "max-step-distance" = 26,
                                             "se-artificial:step-length:summer:male" = 0.333271935726846,
                                             "se-forest:turning-angle" = 0.102359124697231,
                                             "beta-scrub:step-length:winter:female" = 0.0274316880128998,
                                             "beta-bare:step-length" = 0.50718636136521,
                                             "se-scrub:distance-to-road" = 0.0375446583250768,
                                             "annual-survival-prob" = 0.97,
                                             "se-wetlands:distance-to-road" = 0,
                                             "se-scrub:step-length" = 0.10753258211162,
                                             "se-bare" = 0.252529144111392,
                                             "se-forest:step-length:summer:female" = 0,
                                             "beta-forest:step-length:summer:male" = 0.122465917359963,
                                             "beta-agricultural:distance-to-road" = -0.18977662926457,
                                             "se-scrub:step-length:summer:female" = 0,
                                             "se-slope:summer" = 0.00221782055170543,
                                             "beta-slope:step-length" = 0.00965050948976871
                            ))



nl@simdesign <- simdesign_ff(nl, nseeds = 1)


# Evaluate nl object:
eval_variables_constants(nl)
print(nl)

# Run all simulations (loop over all siminputrows and simseeds) - parallelised 
library(future)
plan(multisession, workers = 20)
results <- run_nl_all(nl, split = 20)


# Attach results to nl object:
setsim(nl, "simoutput") <- results

# Write output to outpath of experiment within nl
write_simoutput(nl)

# Do further analysis:
analyze_nl(nl)
