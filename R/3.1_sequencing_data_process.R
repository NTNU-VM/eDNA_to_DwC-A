#=========================================================================
# Transform raw sequencing output into occurrence table
# 
# Example file used: Anders_BFR2.otutab.xlsx from Markus
# 
# Input requirements:
# All sample columns - and only the sample columns - (MM1011 etc) should be 
# located to the left of the "#OTU ID" column.
#=========================================================================

library(googlesheets)
library(readxl)
library(tidyverse)
library(xlsx)
library(uuid)

source("R/2_project_functions.R", local = TRUE)


# 1. Grab the sheet
excelFile <- "./Anders_BFR2.otutab.xlsx"

# List tabs
excel_sheets(excelFile)

# Save tab as dataframe
rawSequencingData <- read_excel(excelFile, sheet = "votutab_BFR2.swarms")

#  Check the table is there...
head(rawSequencingData)

# 1. Get info on the table (if available)
if(exists("tableSummary")) {
  tableSummary(rawSequencingData)
}

# Replace spaces (and other chars) in colnames with underscores, or remove
names(rawSequencingData) <- str_replace_all(names(rawSequencingData), 
                                              c(" " = "_" , 
                                                "," = "_" , 
                                                "#" = "" ))

# Remove rows with no species match
rawSequencingData <- filter(rawSequencingData, Best_ID != "No match")

#  Check table again
head(rawSequencingData)

# 2. Get info on the table (if available)
if(exists("tableSummary")) {
  tableSummary(rawSequencingData)
}

# Select subset of columns here (for dev)
# rawSequencingData <- select(rawSequencingData, c("MM1011", "MM1021", "MM1031", "OTU_ID", "Best_ID", "Match_1"))

# Transpose to view... hmmm no use
# rawSequencingData <- transpose(rawSequencingData)


# Assuming that each XL file represents a ...?
# First, need to declare which columns represent the samples (whatever "they" are.. the occurrence.sequencing_IDs)
# ASSUMING all are positioned before the OTU_ID column, they can be identified by index.

# Get number of sample columns (= index of the right-most one)
sampleColumnCount <- grep("^OTU_ID$", colnames(rawSequencingData)) - 1

# Get number of rows in dataset
rowCount <- sapply(rawSequencingData, function(x) length(x))

# Create a new dataframe to take the transformed data.
# transformedData

# Loop through these sample columns
#   Get the colname
#   Loop through each row
#     Get the value
#       If not zero, insert values from this row into a new row, as follows:
#         colname     ->  identificationVerificationStatus / sequencing_ID
#         cell value  ->  organismQuantity
#         OTU_ID      ->  occurrence_ID / sequenceNumber / readName
#         Best_ID     ->  matchingScientificName
#         Match_max   ->  identificationVerificationStatus
#         Search_DB   ->  ?

#create an empty list to hold the transformed data
newList <- list() 
# counter to increment through consecutive loops
rowCounter <- 0

# Loop through the sample columns (by index, not name).
for(i in 1:sampleColumnCount){
  
  # Get column (ie sample) name
  colName <- colnames(rawSequencingData)[i]
  
  # Loop through all the rows
  for (row in 1:nrow(rawSequencingData)) {
    
    # Number of times this OTU showed up in this sample
    otuFrequency <- rawSequencingData[row, colName]
    
    # If the OTU was found in this sample, then collect values for row in destination dataframe
    if(otuFrequency > 0){
      
      # Set row number for the new dataframe
      rowCounter <- rowCounter + 1
      
      # Get the other values required for the new row (to be adjusted..)
      otuID       <- rawSequencingData[row, "OTU_ID"]
      bestID      <- rawSequencingData[row, "Best_ID"]
      matchMax    <- rawSequencingData[row, "Match_1"]
      referenceDB <- rawSequencingData[row, "Search_DB"]
      
      # Construct named vector to hold the new row content (a subset of columns for now..)
      # Fields which are not yet present in the excel sheet are just given string placeholders
      # here to allow column creation.
      # newRow <- c(otuID, otuID, colName, otuID, 
      #             bestID, "taxonID?", "boldID:XXXX?",
      #             referenceDB, "date?", matchMax, 
      #             "idRemarks?", "MIxS:lib_size?", otuFrequency, 
      #             "DNA sequence reads?", "readAbundanceDetails", "sop",	"material sample?", "eDNA?")
      # 
      # names(newRow) = c("occurrence_ID", "sequence_ASV_ID", "sequencing_ID", "readName", 
      #                   "matchingScientificName", "taxonID", "scientificName",
      #                   "identificationReference", "dateIdentified", "identificationVerificationStatus", 
      #                   "identificationRemarks",	"MIxS:lib_size", "organismQuantity", 
      #                   "organismQuantityType", "readAbundanceDetails", "sop",	"basisOfRecord", "dc:type")
      
      newRow = c("occurrence_ID"                    = paste0(otuID, "_", colName)
                 "sequence_ASV_ID"                  = otuID, 
                 "sequencing_ID"                    = colName,
                 "readName"                         = otuID, 
                 "matchingScientificName"           = bestID, 
                 "taxonID"                          = "taxonID?", 
                 "scientificName"                   = "boldID:XXXX?",
                 "identificationReference"          = referenceDB, 
                 "dateIdentified"                   = "date?", 
                 "identificationVerificationStatus" = matchMax, 
                 "identificationRemarks"            = "idRemarks?",	
                 "MIxS:lib_size"                    = "MIxS:lib_size?", 
                 "organismQuantity"                 = otuFrequency, 
                 "organismQuantityType"             = "DNA sequence reads?", 
                 "readAbundanceDetails"             = "readAbundanceDetails?", 
                 "sop"                              = "sop?", 
                 "basisOfRecord"                    = "material sample?", 
                 "dc:type"                          = "eDNA?"
      )
      
      # Add newRow vector to the list
      newList[[rowCounter]] <- newRow 
      
    }
  }
}

# Combine all newRow vectors into a matrix..
newMatrix <- do.call("rbind",newList) 
# ..then dataframe
newDataFrame <- data.frame(newMatrix)


#  Check table again
head(newDataFrame)

# 3. Get info on the table (if available)
if(exists("tableSummary")) {
  tableSummary(newDataFrame)
}

saveAsExcel(theTable = newDataFrame, tableName="Markus_data_transformed", dir="./data/process/")

# END
