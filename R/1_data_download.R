# download data from googlesheet

library(googlesheets)
library(readxl)

# register worksheet (GA - temp: the gs_key method below doesn't work for me)
# eDNA_sheet <- gs_title("GBIF eDNA record format - modified")
eDNA_sheet <- gs_title("GBIF eDNA record v3 - mockup post-meeting")

# register worksheet (worksheet is public, but key needed)
# eDNA_sheet <- gs_key("1uVWOxjJZo0v4uS5L6h8F-1sV5zNs7L_v7g1pSE_o8mY")

# Download entire Google Sheet as xlsx, create folder /data if necessary
dir.create("/data",showWarnings = FALSE)
dataFile <- "./data/eDNA_Data.xlsx"
gs_download(eDNA_sheet, NULL, dataFile, TRUE, TRUE)

# List all sheets (tabs) in the spreadsheet 
excel_sheets(dataFile)

# save individual sheets as dataframes
locality <- read_excel(dataFile, sheet = "locality")
waterSample <- read_excel(dataFile, sheet = "waterSample")
extraction <- read_excel(dataFile, sheet = "extraction")
amplification <- read_excel(dataFile, sheet = "amplification")
sequencing <- read_excel(dataFile, sheet = "sequencing")
occurrence <- read_excel(dataFile, sheet = "occurrence")
sequence <- read_excel(dataFile, sheet = "sequence_ASV")

# save files to local cache
dir.create("./data",showWarnings=FALSE)
saveRDS(locality,"./data/locality.rds")
saveRDS(waterSample,"./data/waterSample.rds")
saveRDS(extraction,"./data/extraction.rds")
saveRDS(amplification,"./data/amplification.rds")
saveRDS(sequencing,"./data/sequencing.rds")
saveRDS(occurrence,"./data/occurrence.rds")
saveRDS(sequence,"./data/sequence.rds")

#....
