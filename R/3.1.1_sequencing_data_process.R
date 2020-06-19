#=========================================================================
# Transform raw sequencing output into occurrence table
# 
# Example file used: FinalMetazoaForGBIF.xlsx from Markus
# 
# Input requirements:
# All sample columns - and only the sample columns - (MM101-1 etc) should be 
# located to the right of the "organismQuantityType" column.
# 
# (deleted a col of ~1880 scientific names from col G, below the main data rows)
# 
# Output:
# /data/output/Markus_data_transformed_v2.xslx
#=========================================================================

library(googlesheets)
library(readxl)
library(tidyverse)
library(xlsx)
library(uuid)
library(tictoc)

source("R/2_project_functions.R", local = TRUE)

#==================================================
# User options
#==================================================

# Set the source excel file path
excelFile <- "./data/source/FinalMetazoaForGBIF.xlsx"

# Set marker column (last column before sample columns)
markerColName <- "organismQuantityType"

# Set the number of sample columns to be processed (reduce for faster testing). 
# Options: "all" | integer from 1 - total number of sample cols (counts from first sample col)
maxSampleCols <- 5

# Set the number of rows to be processed (reduce for faster testing). 
# Options: "all" | integer from 1 - total number of rows (counts from row 1)
maxRows <- "all"

# Set whether intermediate steps should be summarised and output (slower)
showSteps <- FALSE

#==================================================

# Start timer(s) (for optimisation)
# 
tic.clearlog()
tic("Total")
tic("1. Transform data")


# 1. Grab the sheet and remove unnecessary cols/rows

# List tabs
excel_sheets(excelFile)

# Save tab as dataframe
rawSequencingData <- read_excel(excelFile, sheet = "Sheet1")

#  Check the table is there...
if(showSteps) {
  head(rawSequencingData)
}

# i. Get info on the table (if available)
if(showSteps && exists("tableSummary")) {
  tableSummary(rawSequencingData)
}

# Replace spaces (and other chars) in colnames with underscores, or remove
names(rawSequencingData) <- str_replace_all(names(rawSequencingData), 
                                            c(" " = "_" , 
                                              "," = "_" , 
                                              "#" = "" ))

# Remove rows with no species match 
# (Not used in this sheet format, but can be altered if required)
# rawSequencingData <- filter(rawSequencingData, Best_ID != "No match")

#  Check table again
if(showSteps) {
  head(rawSequencingData)
}

# ii. Get info on the table (if available)
if(showSteps && exists("tableSummary")) {
  tableSummary(rawSequencingData)
}

# Set columns for processing
# Declare which columns represent the samples (reads)
# - assuming all are positioned after the marker column.

markerSearchString <- paste0("^",markerColName,"$")

# Get column vars for use
columnCount <- ncol(rawSequencingData)
referenceColIndex <- grep(markerSearchString, colnames(rawSequencingData))
sampleColumnCount <- columnCount - referenceColIndex


# Optionally select subset of sample columns by quantity (for testing)
if(maxSampleCols < sampleColumnCount){
  # Get raw dataset column vars
  columnCount <- ncol(rawSequencingData)
  referenceColIndex <- grep(markerSearchString, colnames(rawSequencingData))
  sampleColumnCount <- columnCount - referenceColIndex
  
  # Show raw dataset specs
  columnCount
  referenceColIndex
  sampleColumnCount
  
  # Method 1: reset the index of the last sample col to be reached
  # (add: else {lastSampleColIndex <- rawColumnCount} )
  # lastSampleColIndex = firstSampleColIndex + maxSampleCols
  
  # Method 2: subselect the entire table (faster for subsequent summary views)
  lastIndex <- referenceColIndex + maxSampleCols
  rawSequencingData <- rawSequencingData[ , 1:lastIndex]
}

# Optionally select subset of columns by name (for testing)
# This applies to all columns.
# !If used - include markerColName immediately before the sample cols
# rawSequencingData <- select(rawSequencingData, c("recordNumber", 
#   "genus", "specificEpithet", "scientificName", "taxonRank", "identificationRemarks",
#   "dateIdentified", "organismQuantityType", "MM101-1", "MM101-2", "MM101-3", "MM102-1"))


# Set / reset column vars for use
columnCount <- ncol(rawSequencingData)
referenceColIndex <- grep(markerSearchString, colnames(rawSequencingData))
sampleColumnCount <- columnCount - referenceColIndex
firstSampleColIndex <- referenceColIndex + 1
lastSampleColIndex <- columnCount

# Show colum vars for use
columnCount
referenceColIndex
sampleColumnCount
firstSampleColIndex
lastSampleColIndex


# Set rows for processing
rowCount = nrow(rawSequencingData)

if(maxRows != "all" && is.numeric(maxRows) && length(maxRows)>0 && maxRows <= rowCount){
  rawSequencingData <- rawSequencingData[1:maxRows,]
  rowCount <- maxRows
}

#  Check table again
if(showSteps) {
  head(rawSequencingData)
}

# iii. Get info on the truncated table
if(showSteps && exists("tableSummary")) {
  tableSummary(rawSequencingData)
}

# check values
columnCount
rowCount
referenceColIndex
firstSampleColIndex
lastSampleColIndex
sampleColumnCount
rowCount


# 2. Create a new dataframe to take the transformed data.
# transformedData

# Loop through these sample columns
# Algorithm:
#   Get the sampleColName
#   Loop through each row
#     Get the value (OTU count) for that col
#       If not zero, insert all values from this row into a row in the new table


#create an empty list to hold the transformed data
newList <- list() 

# Count number of OTU 'hits' (>0) across all samples 
# Equivalent to a row counter for the transformed data table
otuHitCount <- 0

# Loop through the sample columns (by index, not name).
for(i in firstSampleColIndex:lastSampleColIndex){
  
  # Get column name (ie sample name)
  sampleColName <- colnames(rawSequencingData)[i]
  # cat(paste0("Col name:", sampleColName, "; index: ", i, "\n"))
  
  # Loop through all rows
  for (row in 1:nrow(rawSequencingData)) {
    
    # Number of times this OTU showed up in this sample
    otuFrequency <- rawSequencingData[row, sampleColName]
    # cat(paste0("otuFrequency: ", otuFrequency, "\n"))
    
    # If the OTU was found in this sample, then collect values for row in destination dataframe
    if(!is.na(otuFrequency) && otuFrequency > 0) {
      
      # Increment OTU hit count
      otuHitCount <- otuHitCount + 1
      
      # Columns in raw dataset:
      # recordNumber
      # associatedSequences
      # superkingdom
      # kingdom
      # phylum
      # class
      # order
      # family
      # genus
      # specificEpithet
      # scientificName
      # taxonRank
      # identificationRemarks
      # identificationReferences
      # dateIdentified
      # organismQuantityType
      
      # Get the other values required for the new row
      # (some commented for dev)
      recordNumber          <- rawSequencingData[row, "recordNumber"]
      associatedSequences   <- rawSequencingData[row, "associatedSequences"]
      superkingdom          <- rawSequencingData[row, "superkingdom"]
      kingdom               <- rawSequencingData[row, "kingdom"]
      phylum                <- rawSequencingData[row, "phylum"]
      class                 <- rawSequencingData[row, "class"]
      order                 <- rawSequencingData[row, "order"]
      family                <- rawSequencingData[row, "family"]
      genus                 <- rawSequencingData[row, "genus"]
      specificEpithet       <- rawSequencingData[row, "specificEpithet"]
      scientificName        <- rawSequencingData[row, "scientificName"]
      taxonRank             <- rawSequencingData[row, "taxonRank"]
      identificationRemarks <- rawSequencingData[row, "identificationRemarks"]
      identificationReferences <- rawSequencingData[row, "identificationReferences"]
      dateIdentified        <- rawSequencingData[row, "dateIdentified"]
      organismQuantityType  <- rawSequencingData[row, "organismQuantityType"]
      
      # Construct named vector to hold the new row content.
      # New fields can be constructed here. Those without values yet can be given string placeholders
      # here to allow column creation.
      
      # a. The most intuitive way to build the vector, but produces a very annoying error: column names end up 
      # duplicated, eg "recordNumber.recordNumber", "genus.genus" etc.
      # newRow = c("occurrence_ID"                    = paste0(recordNumber, "_", sampleColName),
      #            "sample_ID"                        = sampleColName,
      #            "otuFrequencyPerSample"            = otuFrequency,
      #            "recordNumber"                     = recordNumber,
      #            
      #            "associatedSequences"              = associatedSequences,
      #            "superkingdom"                     = superkingdom,
      #            "kingdom"                          = kingdom,
      #            "phylum"                           = phylum,
      #            
      #            "class"                            = class,
      #            "order"                            = order,
      #            "family"                           = family,
      #            "genus"                            = genus,
      #            
      #            "specificEpithet"                  = specificEpithet,
      #            "scientificName"                   = scientificName,
      #            "taxonRank"                        = taxonRank,
      #            "identificationRemarks"            = identificationRemarks,
      #            
      #            "identificationReferences"         = identificationReferences,
      #            "dateIdentified"                   = dateIdentified,
      #            "organismQuantityType"             = organismQuantityType
      # )
      
      # b. Alternative way to build named vector - works ok but more prone to name-value mismatches.
      newRow <- c(paste0(recordNumber, "_", sampleColName),
                  sampleColName,
                  otuFrequency,
                  recordNumber,
                  
                  associatedSequences,
                  superkingdom,
                  kingdom,
                  phylum,
                  
                  class,
                  order,
                  family,
                  genus,
                  
                  specificEpithet,
                  scientificName,
                  taxonRank,
                  identificationRemarks,
                  
                  identificationReferences,
                  dateIdentified,
                  organismQuantityType
      )
      names(newRow) <- c("occurrence_ID",
                         "sample_ID",
                         "otuFrequencyPerSample",
                         "recordNumber",
                         
                         "associatedSequences",
                         "superkingdom",
                         "kingdom",
                         "phylum",
                         
                         "class",
                         "order",
                         "family",
                         "genus",
                         
                         "specificEpithet",
                         "scientificName",
                         "taxonRank",
                         "identificationRemarks",
                         
                         "identificationReferences",
                         "dateIdentified",
                         "organismQuantityType"
      )
      
      # Add newRow vector to the list
      newList[[otuHitCount]] <- newRow 
      
    } # End main processing block in which otuFrequency > 0
  } # End loop through all rows
} # End loop through the sample columns


# Combine all newRow vectors into a matrix..
newMatrix <- do.call("rbind",newList) 
# ..then dataframe
newDataFrame <- data.frame(newMatrix)


#  Check table again
if(showSteps) {
  head(newDataFrame)
}

# iv. Get info on the table (if available)
if(showSteps && exists("tableSummary")) {
  tableSummary(newDataFrame)
}
toc(log = TRUE, quiet = TRUE) # End of "Transform data"

# If there is any transformed data to save, output as file.
tic("2. Create output file")

if(otuHitCount > 0){
  # Excel option
  saveAsExcel(theTable = newDataFrame, tableName="Markus_data_transformed_v2", dir="./data/output/")
  
  # CSV option (throws error:
  # - "Error in write.table(newDataFrame, file = "Markus_data_transformed_v2.csv",  : unimplemented type 'list' in 'EncodeElement'"
  # - have not solved this yet.
  # write.csv(newDataFrame, file = "Markus_data_transformed_v2.csv")
  
  report <- paste0("OTU hit count (ie >0 frequency per sample) = ", otuHitCount, ".")
} else {
  report <- "No transformed data to output. (OTU hit count = 0)."
}
toc(log = TRUE, quiet = TRUE) # End of "Create output file"

toc(log = TRUE, quiet = TRUE) # End of "Total"

# Output timing data
log.txt <- tic.log(format = TRUE)
tic.clearlog()
writeLines(unlist(log.txt))

cat(sep="", "\n", report, "\n")

# END