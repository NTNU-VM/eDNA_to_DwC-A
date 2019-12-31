#=========================================================================
# Step 1 script for spreadsheet-to-IPT pipeline prototype.
# 
# Download raw data from googlesheet
# and separate into individual sheets.
#=========================================================================

library(googlesheets)
library(readxl)

#==================================================
# User options
#==================================================

# Select raw data file source
#   1 - google sheet
#   2 - local excel file
fileSource <- 2

# Excel file path.
dataFile <- "./data/raw/eDNA_Data.xlsx"

#==================================================

# Create dir for raw data files
dir.create("./data/raw", showWarnings = FALSE)

# Get google sheet
if(fileSource == 1) {
  
  # register worksheet (GA - temp: the gs_key method below doesn't work for me)
  # eDNA_sheet <- gs_title("GBIF eDNA record format - modified")
  # eDNA_sheet <- gs_title("GBIF eDNA record v3 - mockup post-meeting")
  # eDNA_sheet <- gs_title("GBIF eDNA record v3 - dummy data")
  eDNA_sheet <- gs_title("GBIF eDNA record format")
  
  # register worksheet (worksheet is public, but key needed)
  # eDNA_sheet <- gs_key("1uVWOxjJZo0v4uS5L6h8F-1sV5zNs7L_v7g1pSE_o8mY")
  
  # Download entire Google Sheet as xlsx, create folder /data if necessary
  # dataFile <- excelFilePath
  # Load google sheet into excel format
  gs_download(eDNA_sheet, NULL, dataFile, TRUE, TRUE)
  
} else {
  # use the local excel file
}


# List all sheets (tabs) in the spreadsheet (for checking)
excel_sheets(dataFile)

# save individual sheets as dataframes
locality <- read_excel(dataFile, sheet = "locality")
waterSample <- read_excel(dataFile, sheet = "waterSample")
extraction <- read_excel(dataFile, sheet = "extraction")
amplification <- read_excel(dataFile, sheet = "amplification")
sequencing <- read_excel(dataFile, sheet = "sequencing")
occurrence <- read_excel(dataFile, sheet = "occurrence")
sequence_ASV <- read_excel(dataFile, sheet = "sequence_ASV")

# save files to local cache
saveRDS(locality,"./data/raw/locality.rds")
saveRDS(waterSample,"./data/raw/waterSample.rds")
saveRDS(extraction,"./data/raw/extraction.rds")
saveRDS(amplification,"./data/raw/amplification.rds")
saveRDS(sequencing,"./data/raw/sequencing.rds")
saveRDS(occurrence,"./data/raw/occurrence.rds")
saveRDS(sequence_ASV,"./data/raw/sequence_ASV.rds")

## For testing only- remove
# rm(list = ls())
# objects()

