# download data from googlesheet

library(googlesheets)

# register worksheet
eDNA_sheet <- gs_title("GBIF eDNA record format")

# download individual sheets as dataframes
locality <- gs_read(ss=eDNA_sheet, ws = "locality")
waterSample <- gs_read(ss=eDNA_sheet, ws = "waterSample")
extraction <- gs_read(ss=eDNA_sheet, ws = "extraction")


# save files to local cache
dir.create("./data",showWarnings=FALSE)
saveRDS(locality,"./data/locality.rds")
saveRDS(waterSample,"./data/waterSample.rds")
saveRDS(extraction,"./data/extraction.rds")
