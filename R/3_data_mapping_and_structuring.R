#=========================================================================
# Main script for spreadsheet-to-IPT pipeline prototype.
# 
# Input requirements:
# One worksheet with spreadsheets named as follows:
#   locality
#   waterSample
#   extraction
#   amplification
#   sequencing
#   occurrence
#   sequence_ASV

# Output:
# Excel files configured ready for upload to IPT Occurrence Core and Extensions:
#   IPT_coreOccurrenceTable.xlsx
#   IPT_ExtData_GGBN_Amplification.xlsx
#   IPT_ExtData_GGBN_Preparation.xlsx
#   IPT_ExtData_MIxS_Sample.xlsx
#   IPT_ExtData_MoF.xlsx
# 
# Output files located in: ./data/output/
#=========================================================================

library(tidyverse)
library(xlsx)
library(uuid)


source("R/1_data_download.R", local = TRUE)
source("R/2_project_functions.R", local = TRUE)

# For output during process: for testing
dir.create("./data/process",showWarnings=FALSE)

# For final output files
dir.create("./data/output",showWarnings=FALSE)


# Fetch the stored tables
locality <- readRDS("./data/raw/locality.rds")
waterSample <- readRDS("./data/raw/waterSample.rds")
extraction <- readRDS("./data/raw/extraction.rds")
amplification <- readRDS("./data/raw/amplification.rds")
sequencing <- readRDS("./data/raw/sequencing.rds")
occurrence <- readRDS("./data/raw/occurrence.rds")
sequence_ASV <- readRDS("./data/raw/sequence_ASV.rds")


# Prefix all column names with table names to avoid clashes.
colnames(locality) <- paste("locality", colnames(locality), sep = ".")
colnames(waterSample) <- paste("waterSample", colnames(waterSample), sep = ".")
colnames(extraction) <- paste("extraction", colnames(extraction), sep = ".")
colnames(amplification) <- paste("amplification", colnames(amplification), sep = ".")
colnames(sequencing) <- paste("sequencing", colnames(sequencing), sep = ".")
colnames(occurrence) <- paste("occurrence", colnames(occurrence), sep = ".")
colnames(sequence_ASV) <- paste("sequence_ASV", colnames(sequence_ASV), sep = ".")

# TODO
# Do checks on primary keys for duplicates
# Generate uuids for eventID and parentEventIDs -DONE
# UUIDgenerate()
# UUIDgenerate(use.time = TRUE)

#=========================================================================
# 0. Generate UUIDs for GBIF's ID columns where needed
#    - eventID and parentEventID in waterSample and extraction tables
#    - materialSampleID in waterSample and extraction tables
#=========================================================================

#-------------------------------------------------------
# 0a.  Generate UUIDs for eventID and parentEventID in waterSample and extraction tables
#-------------------------------------------------------

# Table info (relevant cols only, for full colnames)
head(waterSample %>% select(1:3,5,6))
head(extraction %>% select(1:4,6))
tableSummary(waterSample)
tableSummary(extraction)

# Generate waterSample.eventIDs
for(i in 1:length(waterSample$waterSample.eventID)){
  waterSample$waterSample.eventID[i] <- UUIDgenerate()
}

# Generate extraction.eventIDs
for(i in 1:length(extraction$extraction.eventID)){
  extraction$extraction.eventID[i] <- UUIDgenerate()
}

# Get extraction.parentEventIDs
# Use the natural P and F keys (waterSampleID) to select waterSample.eventID values.
extraction$extraction.parentEventID[
  extraction$extraction.waterSampleID == waterSample$waterSample.waterSampleID
  ] = waterSample$waterSample.eventID


#-------------------------------------------------------
# 0b.  Generate UUIDs for materialSampleID in waterSample and extraction tables
#-------------------------------------------------------

# Generate waterSample.materialSampleIDs
for(i in 1:length(waterSample$waterSample.materialSampleID)){
  waterSample$waterSample.materialSampleID[i] <- UUIDgenerate()
}

# Generate/get extraction.materialSampleIDs
# TODO - need to know if these are really the same as the waterSample.materialSampleIDs (A) or 
# independent (B), ie if they are subsamples of water samples...

# Comment installas appropriate:

# A. If extraction.materialSampleIDs are inherited from waterSample.materialSampleIDs, then:
extraction$extraction.materialSampleID[
  extraction$extraction.waterSampleID == waterSample$waterSample.waterSampleID
  ] = waterSample$waterSample.materialSampleID

# or B. If extraction samples have their own IDs, then:
# for(i in 1:length(waterSample$waterSample.materialSampleID)){
#   waterSample$waterSample.materialSampleID[i] <- UUIDgenerate()
# }


# Table info (relevant cols only, for full colnames)
head(waterSample %>% select(1:3,5,6))
head(extraction %>% select(1:4,6))
tableSummary(waterSample)
tableSummary(extraction)

#=========================================================================
# 1. De-normalise all data into one table
#=========================================================================

#-------------------------------------------------------
# 1a.  Add locality to waterSample
#-------------------------------------------------------

# Pre-joined table stats
tableSummary(locality)
tableSummary(waterSample)

# stripped out duplicates from locality table to make this join work. Needs tweaked if likely to be duplicates.
locality_waterSample <- left_join(waterSample,locality,
                                  by = c("waterSample.localityID" = "locality.localityID"))

# Joined table stats
tableSummary(locality_waterSample)

# save step as file for testing
saveAsExcel(theTable = locality_waterSample, tableName="1_locality_waterSample", dir="./data/process/")
  

#-------------------------------------------------------
# 1b.  Add extraction
#-------------------------------------------------------
# Pre-joined table stats
tableSummary(extraction)

all_and_extraction <- left_join(locality_waterSample, extraction,
                                by = c("waterSample.waterSampleID" = "extraction.waterSampleID"))

# Joined table stats
tableSummary(all_and_extraction)

# save step as file for testing
saveAsExcel(theTable = all_and_extraction, tableName="2_all_and_extraction", dir="./data/process/")


#-------------------------------------------------------
# 1c.  Add amplification
#-------------------------------------------------------
# Pre-joined table stats
tableSummary(amplification)

all_and_amplification <- left_join(all_and_extraction, amplification,
                                   by = c("extraction.extractionID" = "amplification.extractionID"))
# Joined table stats
tableSummary(all_and_amplification)

# tableToExcel <- data.frame(all_and_amplification)
saveAsExcel(theTable = all_and_amplification, tableName="3_all_and_amplification", dir="./data/process/")


#-------------------------------------------------------
# 1d.  Add sequencing
#-------------------------------------------------------
# Pre-joined table stats
tableSummary(sequencing)

all_and_sequencing <- left_join(all_and_amplification, sequencing,
                                by = c("amplification.sequencingID" = "sequencing.sequencingID"))
# Result: 12 rows

# Try right join
# all_and_sequencing <- right_join(all_and_amplification, sequencing,
#                                 by = c("amplification.sequencingID" = "sequencing.sequencingID"))
# Result: 

# Joined table stats
tableSummary(all_and_sequencing)

# tableToExcel <- data.frame(all_and_sequencing)
saveAsExcel(theTable = all_and_sequencing, tableName="4_all_and_sequencing", dir="./data/process/")


#-------------------------------------------------------
# 1e.  Add occurrence
#-------------------------------------------------------
# Pre-joined table stats
tableSummary(occurrence)

all_and_occurrence <- left_join(all_and_sequencing, occurrence,
                                by = c("amplification.sequencingID" = "occurrence.sequencingID"))

# Joined table stats
tableSummary(all_and_occurrence)

# tableToExcel <- data.frame(all_and_occurrence)
saveAsExcel(theTable = all_and_occurrence, tableName="5_all_and_occurrence", dir="./data/process/")


#-------------------------------------------------------
# 1f.  Add sequence_ASV
#-------------------------------------------------------
# Pre-joined table stats
tableSummary(sequence_ASV)

all_and_sequence_ASV <- left_join(all_and_occurrence, sequence_ASV,
                                  by = c("occurrence.sequenceID" = "sequence_ASV.sequenceID"))

# Joined table stats
tableSummary(all_and_sequence_ASV)

# save as rds for use in next steps
saveRDS(all_and_sequence_ASV,"./data/process/all_and_sequence_ASV.rds")

# tableToExcel <- data.frame(all_and_sequence_ASV)
saveAsExcel(theTable = all_and_sequence_ASV, tableName="6_all_and_sequence_ASV", dir="./data/process/")

#-------------------------------------------------------
# 1g.  Now save as master file for next steps
#-------------------------------------------------------
library(googledrive)

# save in R format
flatDataMaster <- readRDS("./data/process/all_and_sequence_ASV.rds")

# Save as xlsx
saveAsExcel(theTable = flatDataMaster, tableName="flatDataMaster", dir="./data/process/")


# Lines from AF
# # event_core_take1 <- bind_rows(location_and_waterSample_to_Event_core,extraction_to_event_core)
# 
# # 1b) reorder columns
# event_core_take1 <- event_core_take1 %>%
#   select(eventID,parentEventID,locality,eventDate,samplingProtocol)

# To remove all "No match" rows.
# matchingOccurrences <- occurrence %>% filter(!str_detect(matchingScientificName, "No match"))
# #head(matchingOccurrences)



#=========================================================================
# 2. Split into tables for the occurrence core and each core extension
#=========================================================================


#-------------------------------------------------------
# 2a. Mapping to Occurrence Core
#-------------------------------------------------------

## 
## - update this select() when field names are updated!
coreOccurrenceTable <- select(flatDataMaster, 
                              "occurrenceID" = "occurrence.sequenceID",
                              starts_with("locality."),
                              starts_with("waterSample."),
                              starts_with("extraction."),
                              -starts_with("extraction.GGBN"),
                              starts_with("occurrence."),
                              -starts_with("occurrence.MIxS"),
                              starts_with("sequence_ASV."),
                              -starts_with("sequence_ASV.GGBN"))

# table details
tableSummary(coreOccurrenceTable)

# save as rds
saveRDS(coreOccurrenceTable,"./data/process/coreOccurrenceTable.rds")

# save step as file for testing
saveAsExcel(theTable = coreOccurrenceTable, tableName="coreOccurrenceTable", dir="./data/process/")

# TODO 
# - 50% of rows are duplicates at this point.
# - Need to establish where the duplication occurs and change the join method..
# Maybe where occurrence is merged in..

## Remove all duplicate rows
coreOccurrenceTable <- coreOccurrenceTable %>% distinct()

# table details
tableSummary(coreOccurrenceTable)

# Remove all tablename prefixes to allow auto mapping
# Up to and inc "."
colnames(coreOccurrenceTable) <- gsub("^.*?\\.", "", colnames(coreOccurrenceTable))

# Refs
# https://stackoverflow.com/questions/45960269/removing-suffix-from-column-names-using-rename-all
# https://stackoverflow.com/questions/25991824/remove-all-characters-before-a-period-in-a-string
tableSummary(coreOccurrenceTable)

# save step as file for IPT
saveAsExcel(theTable = coreOccurrenceTable, tableName="IPT_coreOccurrenceTable", dir="./data/output/")

#-------------------------------------------------------
# 2b. mapping to GGBN Preparation Extension
#-------------------------------------------------------

## TODO 
## - Add eventID & parentEventID fields for linking.
## - update this select() when field names are updated!

ExtData_GGBN_Preparation <- select(flatDataMaster, 
                              "occurrenceID" = "occurrence.sequenceID",
                              starts_with("extraction.GGBN-P:"),
                              "preparationDate" = "waterSample.eventDate")

# table details
tableSummary(ExtData_GGBN_Preparation)

# save as rds
saveRDS(ExtData_GGBN_Preparation,"./data/process/ExtData_GGBN_Preparation.rds")

# save step as file for testing
saveAsExcel(theTable = ExtData_GGBN_Preparation, tableName="ExtData_GGBN_Preparation", dir="./data/process/")

# Remove all tablename and extension name prefixes to allow auto mapping
# Up to and inc ":"
colnames(ExtData_GGBN_Preparation) <- gsub("^.*?\\:", "", colnames(ExtData_GGBN_Preparation))
tableSummary(ExtData_GGBN_Preparation)

# save step as file for IPT
saveAsExcel(theTable = ExtData_GGBN_Preparation, tableName="IPT_ExtData_GGBN_Preparation", dir="./data/output/")

#-------------------------------------------------------
# 2c. mapping to GGBN Amplification Extension
#-------------------------------------------------------

## TODO 
## - Add eventID & parentEventID fields for linking.
## - update this select() when field names are updated!

ExtData_GGBN_Amplification <- select(flatDataMaster,
                                     "occurrenceID" = "occurrence.sequenceID",
                                     starts_with("amplification.GGBN-A"),
                                     starts_with("sequencing.GGBN-A"),
                                     starts_with("sequence_ASV.GGBN-A"))

# table details
tableSummary(ExtData_GGBN_Amplification)

# save as rds
saveRDS(ExtData_GGBN_Amplification,"./data/process/ExtData_GGBN_Amplification.rds")

# save step as file for testing
saveAsExcel(theTable = ExtData_GGBN_Amplification, tableName="ExtData_GGBN_Amplification", dir="./data/process/")

# Remove all tablename and extension name prefixes to allow auto mapping
# Up to and inc ":"
colnames(ExtData_GGBN_Amplification) <- gsub("^.*?\\:", "", colnames(ExtData_GGBN_Amplification))
tableSummary(ExtData_GGBN_Amplification)

# save step as file for IPT
saveAsExcel(theTable = ExtData_GGBN_Amplification, tableName="IPT_ExtData_GGBN_Amplification", dir="./data/output/")

#-------------------------------------------------------
# 2d. mapping to MIxS Sample Extension
#-------------------------------------------------------

## TODO 
## - Add eventID & parentEventID fields for linking.
## - update this select() when field names are updated!

ExtData_MIxS_Sample <- select(flatDataMaster,
                              "occurrenceID" = "occurrence.sequenceID",
                              starts_with("sequencing.MIxS"),
                              starts_with("occurrence.MIxS"))

# table details
tableSummary(ExtData_MIxS_Sample)

# save as rds
saveRDS(ExtData_MIxS_Sample,"./data/process/ExtData_MIxS_Sample.rds")

# save step as file for testing
saveAsExcel(theTable = ExtData_MIxS_Sample, tableName="ExtData_MIxS_Sample", dir="./data/process/")

# Remove all tablename and extension name prefixes to allow auto mapping
# Up to and inc ":"
colnames(ExtData_MIxS_Sample) <- gsub("^.*?\\:", "", colnames(ExtData_MIxS_Sample))
tableSummary(ExtData_MIxS_Sample)

# save step as file for IPT
saveAsExcel(theTable = ExtData_MIxS_Sample, tableName="IPT_ExtData_MIxS_Sample", dir="./data/output/")

#-------------------------------------------------------
# 2e. mapping to (Core/Extended) Measurement or Facts Extention
#-------------------------------------------------------

# The fields to use here depend on which occurrences are to be registered, eg
#   1. One entry for each sequence_ASV PER original field sample (water/soil from a time & place). This could mean 
#      >1 entry per species per field sample if different sequence_ASVs indicate the same species.
#      Or, at the other extreme,
#   2. An entry for every sequence_ASV even if there are multiple instances from each original sample. If this
#      option, do we take just one instance per sub-fieldSample or per amplification or per sequencing? If so, 
#      do we include the duplicates in the submission?
# For now I will implement 1.

# Also, what about field samples which produce no occurrences (ie recognised species)? Should,
#   A. the reads from these also be registered in GBIF so that they can be identified in 
#      future and "become" occurrences? or
#   B. should they be removed from the current submission until reads have been identified?
# For now I will implement B.


library(reshape2)

#see 
# melt.data.frame {reshape2} etc
# google, "r rearrange data use column name for name and value for value"
# https://aberdeenstudygroup.github.io/studyGroup/lessons/SG-T1-GitHubVersionControl/VersionControl/

# Basic cols to use for MoF:
# measurementID
# measurementType
# measurementValue

# Select fields from master table
# This includes most entity IDs to show where the occurrences are coming from.
ExtData_MoF <- select(flatDataMaster,
                      "waterSampleID" = "waterSample.waterSampleID",
                      "extractionID" = "extraction.extractionID",
                      "amplificationNumber" = "amplification.amplificationNumber",
                      "sequencingID" = "amplification.sequencingID",
                      "occurrenceID" = "occurrence.sequenceID",
                      "waterBodyID" = "locality.waterBodyID",
                      "readName" = starts_with("occurrence.read"),
                      "consensusSequence" = "sequence_ASV.GGBN-A:consensusSequence")

# table details - untransformed
tableSummary(ExtData_MoF)
# ExtData_MoF

# save step as file for testing
saveAsExcel(theTable = ExtData_MoF, tableName="ExtData_MoF", dir="./data/process/")


# Rearrange value columns into type-vale pairs in two columns
# ExtData_MoF <- melt(ExtData_MoF, 
#                      id=c("occurrenceID"), 
#                      measure=c("readName"),
#                      variable.name="measurementType", 
#                      value.name="measurementValue")

# Alternative syntax, adding more variables
ExtData_MoF <- ExtData_MoF %>% melt(id.vars=c("occurrenceID"),
                                    measure=c("readName", "waterBodyID", "consensusSequence"),
                                    variable.name="measurementType",
                                    value.name="measurementValue") %>%
  distinct() %>%
  arrange(occurrenceID)

# Remove all duplicate rows
# ExtData_MoF <- distinct(ExtData_MoF)

# Order by key field (for checking)
# ExtData_MoF <- ExtData_MoF[order(ExtData_MoF$occurrenceID),]

# table details - transformed
tableSummary(ExtData_MoF)

cat(paste("To illustrate MoF table structure:", "\n"))
head(ExtData_MoF)

# save as file for IPT
saveAsExcel(theTable = ExtData_MoF, tableName="IPT_ExtData_MoF", dir="./data/output/")


# 
# END OF SCRIPT
# 