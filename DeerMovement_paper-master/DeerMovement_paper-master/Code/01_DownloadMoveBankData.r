###############################
# download data from movebank
#############################

library(move2)
library(keyring)

cred2<-movebank_store_credentials("Hannah.S","Morphee1")
id=movebank_get_study_id("cervus elaphus corsicanus")
df<- movebank_download_study(study_id = id)

saveRDS(df, "Outputs/RawMoveData.RDS")