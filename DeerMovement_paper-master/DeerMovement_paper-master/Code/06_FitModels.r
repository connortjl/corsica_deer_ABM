#######################
#fit models
#####################

library(MuMIn)
library(tidyverse)
library(amt)

#load
df<-readRDS("Outputs/ModelDataframe.RDS")


########################
#modelling
###########################
# saturated plausible model
spm <- df |> fit_clogit(
    case_ ~ 
    landcover + slope + distance + sl_ + ta_ +
    sl_:landcover + ta_:distance + ta_:landcover + sl_:slope + sl_:sex + landcover:distance + season:slope +distance:season +ta_:slope +
    sl_:sex:season + 
    sl_:sex:season:landcover +
    strata(id) + strata(step_id_))
summary(spm)
AIC(spm)

######################
#complex down
#######################

#remove sl_:sex:season:landcover
m2 <- df |> fit_clogit(
    case_ ~ 
    landcover + slope + distance + sl_ + ta_ +
    sl_:landcover + ta_:distance + ta_:landcover + sl_:slope + sl_:sex + landcover:distance + season:slope +distance:season +ta_:slope +
    sl_:sex:season + 
    strata(id) + strata(step_id_))
AIC(m2)
#worse

# remove ta_:distance
m3 <- df |> fit_clogit(
    case_ ~ 
    landcover + slope + distance + sl_ + ta_ +
    sl_:landcover + ta_:landcover + sl_:slope + sl_:sex + landcover:distance + season:slope +distance:season +ta_:slope +
    sl_:sex:season + 
    sl_:sex:season:landcover +
    strata(id) + strata(step_id_))
AIC(m3)
#better
summary(m3)

# remove sl_:sex
m4 <- df |> fit_clogit(
    case_ ~ 
    landcover + slope + distance + sl_ + ta_ +
    sl_:landcover + ta_:landcover + sl_:slope + landcover:distance + season:slope +distance:season +ta_:slope +
    sl_:sex:season + 
    sl_:sex:season:landcover +
    strata(id) + strata(step_id_))
AIC(m4)
#same
summary(m4)

#remove season:slope
m5 <- df |> fit_clogit(
    case_ ~ 
    landcover + slope + distance + sl_ + ta_ +
    sl_:landcover + ta_:landcover + sl_:slope + landcover:distance + distance:season + ta_:slope +
    sl_:sex:season + 
    sl_:sex:season:landcover +
    strata(id) + strata(step_id_))
AIC(m5)
#better
summary(m5)

#remove distance:season
m6 <- df |> fit_clogit(
    case_ ~ 
    landcover + slope + distance + sl_ + ta_ +
    sl_:landcover + ta_:landcover + sl_:slope + landcover:distance + ta_:slope +
    sl_:sex:season + 
    sl_:sex:season:landcover +
    strata(id) + strata(step_id_))
AIC(m6)
#better
summary(m6)

# remove ta_:landcover
m7 <- df |> fit_clogit(
    case_ ~ 
    landcover + slope + distance + sl_ + ta_ +
    sl_:landcover + sl_:slope + landcover:distance + ta_:slope +
    sl_:sex:season + 
    sl_:sex:season:landcover +
    strata(id) + strata(step_id_))
AIC(m7)
#worse

# remove sl_:sex:season:landcover
m8 <- df |> fit_clogit(
    case_ ~ 
    landcover + slope + distance + sl_ + ta_ +
    sl_:landcover + ta_:landcover + sl_:slope + landcover:distance + ta_:slope +
    sl_:sex:season + 
    strata(id) + strata(step_id_))
AIC(m8)
#worse
summary(m8)

#remove  sl_:sex:season
m9 <- df |> fit_clogit(
    case_ ~ 
    landcover + slope + distance + sl_ + ta_ +
    sl_:landcover + ta_:landcover + sl_:slope + landcover:distance + ta_:slope +
    sl_:sex:season:landcover +
    strata(id) + strata(step_id_))
AIC(m9)
#same
summary(m9)

#emove landcover:ta_
m10 <- df |> fit_clogit(
    case_ ~ 
    landcover + slope + distance + sl_ + ta_ +
    sl_:landcover + sl_:slope + landcover:distance + ta_:slope +
    sl_:sex:season:landcover +
    strata(id) + strata(step_id_))
AIC(m10)
#worse

#remove  sl_:sex:season:landcover
m11 <- df |> fit_clogit(
    case_ ~ 
    landcover + slope + distance + sl_ + ta_ +
    sl_:landcover + ta_:landcover + sl_:slope + landcover:distance + ta_:slope +
    strata(id) + strata(step_id_))
AIC(m11)
# worse

#therfore m9 best
sink("Outputs/BestModel.txt")
summary(m9)
closeAllConnections()


###########################################################################################################
# end of code
#######################################################################################################