library(tidyverse)
library(xlsx)
library(uuid)


source("R/1_data_download.R", local = TRUE)
source("R/2_project_functions.R", local = TRUE)



# Fetch the stored tables
locality <- readRDS("./data/locality.rds")
waterSample <- readRDS("./data/waterSample.rds")
extraction <- readRDS("./data/extraction.rds")
amplification <- readRDS("./data/amplification.rds")
sequencing <- readRDS("./data/sequencing.rds")
occurrence <- readRDS("./data/occurrence.rds")
sequence_ASV <- readRDS("./data/sequence_ASV.rds")

# Prefix all column names with table names to avoid clashes.
colnames(locality) <- paste("locality", colnames(locality), sep = ".")
colnames(waterSample) <- paste("waterSample", colnames(waterSample), sep = ".")
colnames(extraction) <- paste("extraction", colnames(extraction), sep = ".")
colnames(amplification) <- paste("amplification", colnames(amplification), sep = ".")
colnames(sequencing) <- paste("sequencing", colnames(sequencing), sep = ".")
colnames(occurrence) <- paste("occurrence", colnames(occurrence), sep = ".")
colnames(sequence_ASV) <- paste("sequence_ASV", colnames(sequence_ASV), sep = ".")


#=========================================================================
# 1. De-normalise all data into one table
#=========================================================================

#-------------------------------------------------------
# 1a.  Add locality to waterSample
#-------------------------------------------------------

# Pre-join table stats
tableSummary(locality)
tableSummary(waterSample)

# stripped out duplicates from locality table to make this join work. Needs tweaked if likely to be duplicates.
locality_waterSample <- left_join(waterSample,locality,
                                  by = c("waterSample.localityID" = "locality.localityID"))

# Joined table stats
tableSummary(locality_waterSample)

# save step as file for testing
combined_tables <- data.frame(locality_waterSample)
write.xlsx(combined_tables, file="./data/1_locality_waterSample.xlsx", 
           sheetName = "Combined Sheets", col.names=TRUE, row.names=FALSE, showNA=FALSE, append = FALSE)


#-------------------------------------------------------
# 1b.  Add extraction
#-------------------------------------------------------
# Pre-join table stats
tableSummary(extraction)

all_and_extraction <- left_join(locality_waterSample, extraction, 
                                by = c("waterSample.waterSampleID" = "extraction.waterSampleID"))
# Joined table stats
tableSummary(all_and_extraction)

# save step as file for testing
combinedTables <- data.frame(all_and_extraction)
write.xlsx(combinedTables, 
           file="./data/2_all_and_extraction.xlsx", 
           sheetName = "Combined Sheets", col.names=TRUE, row.names=FALSE, showNA=FALSE, append = FALSE)


#-------------------------------------------------------
# 1c.  Add amplification
#-------------------------------------------------------
# Pre-join table stats
tableSummary(amplification)

all_and_amplification <- left_join(all_and_extraction, amplification,
                                   by = c("waterSample.waterSampleID" = "amplification.waterSampleID"))
# Joined table stats
tableSummary(all_and_amplification)

combined_tables <- data.frame(all_and_amplification)
write.xlsx(combined_tables,
           file="./data/3_all_and_amplification.xlsx",
           sheetName = "Combined Sheets", col.names=TRUE, row.names=FALSE, showNA=FALSE, append = FALSE)


#-------------------------------------------------------
# 1d.  Add sequencing
#-------------------------------------------------------
# Pre-join table stats
tableSummary(sequencing)

all_and_sequencing <- left_join(all_and_amplification, sequencing,
                                by = c("amplification.sequencingID" = "sequencing.sequencingID"))
# Joined table stats
tableSummary(all_and_sequencing)

combined_tables <- data.frame(all_and_sequencing)
write.xlsx(combined_tables,
           file="./data/4_all_and_sequencing.xlsx",
           sheetName = "Combined Sheets", col.names=TRUE, row.names=FALSE, showNA=FALSE, append = FALSE)


#-------------------------------------------------------
# 1e.  Add occurrence
#-------------------------------------------------------
# Pre-join table stats
tableSummary(occurrence)

all_and_occurrence <- left_join(all_and_sequencing, occurrence,
                                by = c("amplification.sequencingID" = "occurrence.sequencingID"))
# Joined table stats
tableSummary(all_and_occurrence)

combined_tables <- data.frame(all_and_occurrence)
write.xlsx(combined_tables,
           file="./data/5_all_and_occurrence.xlsx",
           sheetName = "Combined Sheets", col.names=TRUE, row.names=FALSE, showNA=FALSE, append = FALSE)



#-------------------------------------------------------
# 1e.  Add sequence_ASV
#-------------------------------------------------------
# Pre-join table stats
tableSummary(sequence_ASV)

all_and_sequence_ASV <- left_join(all_and_occurrence, sequence_ASV,
                                  by = c("occurrence.sequenceID" = "sequence_ASV.sequenceID"))
# Joined table stats
tableSummary(all_and_sequence_ASV)

# save as rds for use in next steps
saveRDS(all_and_sequence_ASV,"./data/all_and_sequence_ASV.rds")

combined_tables <- data.frame(all_and_sequence_ASV)
write.xlsx(combined_tables,
           file="./data/6_all_and_sequence_ASV.xlsx",
           sheetName = "Combined Sheets", col.names=TRUE, row.names=FALSE, showNA=FALSE, append = FALSE)


#-------------------------------------------------------
# 1f.  Now save as master file for next steps
#-------------------------------------------------------
library(googledrive)

# Do checks on primary keys for duplicates
# Generate uuids for eventID and parentEventIDs
# UUIDgenerate()
# UUIDgenerate(use.time = TRUE)


# save in R format
flatDataMaster <- readRDS("./data/all_and_sequence_ASV.rds")

# # Save as googlesheet - works but slow
# gs_new(title = "flatDataMaster", 
#        ws_title = "flatDataMaster",
#        input = flatDataMaster,
#        trim = TRUE)

# # Move the file created by gs_new (in google drive root) - works
# drive_mv("~/flatDataMaster", 
#          path = "~/NTNU INH stuff/eDNA_to_DwC-A/data/",
#          overwrite = TRUE)

# Alternatively, save as xlsx and then upload to googledrive
combined_tables <- data.frame(flatDataMaster)
excelFile <- write.xlsx(combined_tables,
           file="./data/flatDataMaster.xlsx",
           sheetName = "flatDataMaster", col.names=TRUE, row.names=FALSE, showNA=FALSE, append = FALSE)

# works - much faster than gs_new() and drive_mv()
# (drive_put() doesn't like rds files)
newGoogleSheet <- drive_put("./data/flatDataMaster.xlsx", 
                            path = "~/NTNU INH stuff/eDNA_to_DwC-A/data/",
                            name = "flatDataMaster",
                            type = "spreadsheet")

# Update the existing sheet
newSheetKey <- gs_title("flatDataMaster")


## NEXT: 
## Split main table into tables for each core/extension, and remove duplicate rows.
## Extract fields which are to go into EMoFs.


# ignore below for now..

# This xlsx file maps well to the DwC-A core Event
# see https://data.gbif.no/ipt-test/manage/resource?r=ga-test-7
# Only one field (sampleNumber) left unmapped; sampleNumber is embedded as the 2nd element in fieldNumber.

# Alternative join
# merge(waterSample,locality, by = by.x = "locality", by.y = "locality",
#       by.x = by, by.y = by, all = FALSE, all.x = all, all.y = all,
#       sort = TRUE, suffixes = c(".x",".y"), no.dups = TRUE,
#       incomparables = NULL, ...)



# # event_core_take1 <- bind_rows(location_and_waterSample_to_Event_core,extraction_to_event_core)
# 
# # 1b) reorder columns
# event_core_take1 <- event_core_take1 %>%
#   select(eventID,parentEventID,locality,eventDate,samplingProtocol)
# 
# # removing all "No match" rows.
# matchingOccurrences <- occurrence %>% filter(!str_detect(matchingScientificName, "No match"))
# #head(matchingOccurrences)



#=========================================================================
# 2. Split into tables for the occurrence core and each core extension
#=========================================================================


#-------------------------------------------------------
# 2a. Mapping to Occurrence Core
#-------------------------------------------------------

## TODO
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
saveRDS(coreOccurrenceTable,"./data/coreOccurrenceTable.rds")

# save step as file for testing
split_table <- data.frame(coreOccurrenceTable)
write.xlsx(split_table,
           file="./data/coreOccurrenceTable.xlsx",
           sheetName = "coreOccurrenceTable", col.names=TRUE, row.names=FALSE, showNA=FALSE, append = FALSE)

# Remove all tablename prefixes to allow auto mapping
# Up to and inc "."
colnames(coreOccurrenceTable) <- gsub("^.*?\\.", "", colnames(coreOccurrenceTable))
tableSummary(coreOccurrenceTable)

# save step as file for IPT
split_table <- data.frame(coreOccurrenceTable)
write.xlsx(split_table,
           file="./data/IPT_coreOccurrenceTable.xlsx",
           sheetName = "coreOccurrenceTable", col.names=TRUE, row.names=FALSE, showNA=FALSE, append = FALSE)

# Ref
# https://stackoverflow.com/questions/45960269/removing-suffix-from-column-names-using-rename-all
# https://stackoverflow.com/questions/25991824/remove-all-characters-before-a-period-in-a-string

  
#-------------------------------------------------------
# 2b. mapping to GGBN Preparation Extension
#-------------------------------------------------------

## TODO 
## - Add eventID & parentEventID fields for linking.
## - update this select() when field names are updated!
#
# Feedback from IPT when mapping:
  # Extensions require an ID that links back to the core records.
  # preparationType is required.
  # preparationDate is required.

ExtData_GGBN_Preparation <- select(flatDataMaster, 
                              "occurrenceID" = "occurrence.sequenceID",
                              starts_with("extraction.GGBN-P:"),
                              "preparationDate" = "waterSample.eventDate")
# table details
tableSummary(ExtData_GGBN_Preparation)

# save as rds
saveRDS(ExtData_GGBN_Preparation,"./data/ExtData_GGBN_Preparation.rds")

# save step as file for testing
split_table <- data.frame(ExtData_GGBN_Preparation)
write.xlsx(split_table,
           file="./data/ExtData_GGBN_Preparation.xlsx",
           sheetName = "ExtData_GGBN_Preparation", col.names=TRUE, row.names=FALSE, showNA=FALSE, append = FALSE)

# Remove all tablename and extension name prefixes to allow auto mapping
# Up to and inc ":"
colnames(ExtData_GGBN_Preparation) <- gsub("^.*?\\:", "", colnames(ExtData_GGBN_Preparation))
tableSummary(ExtData_GGBN_Preparation)

# save step as file for IPT
split_table <- data.frame(ExtData_GGBN_Preparation)
write.xlsx(split_table,
           file="./data/IPT_ExtData_GGBN_Preparation.xlsx",
           sheetName = "ExtData_GGBN_Preparation", col.names=TRUE, row.names=FALSE, showNA=FALSE, append = FALSE)


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
saveRDS(ExtData_GGBN_Amplification,"./data/ExtData_GGBN_Amplification.rds")

# save step as file for testing
split_table <- data.frame(ExtData_GGBN_Amplification)
write.xlsx(split_table,
           file="./data/ExtData_GGBN_Amplification.xlsx",
           sheetName = "ExtData_GGBN_Amplification", col.names=TRUE, row.names=FALSE, showNA=FALSE, append = FALSE)

# Remove all tablename and extension name prefixes to allow auto mapping
# Up to and inc ":"
colnames(ExtData_GGBN_Amplification) <- gsub("^.*?\\:", "", colnames(ExtData_GGBN_Amplification))
tableSummary(ExtData_GGBN_Amplification)

# save step as file for IPT
split_table <- data.frame(ExtData_GGBN_Amplification)
write.xlsx(split_table,
           file="./data/IPT_ExtData_GGBN_Amplification.xlsx",
           sheetName = "ExtData_GGBN_Amplification", col.names=TRUE, row.names=FALSE, showNA=FALSE, append = FALSE)


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
saveRDS(ExtData_MIxS_Sample,"./data/ExtData_MIxS_Sample.rds")

# save step as file for testing
split_table <- data.frame(ExtData_MIxS_Sample)
write.xlsx(split_table,
           file="./data/ExtData_MIxS_Sample.xlsx",
           sheetName = "ExtData_MIxS_Sample", col.names=TRUE, row.names=FALSE, showNA=FALSE, append = FALSE)

# Remove all tablename and extension name prefixes to allow auto mapping
# Up to and inc ":"
colnames(ExtData_MIxS_Sample) <- gsub("^.*?\\:", "", colnames(ExtData_MIxS_Sample))
tableSummary(ExtData_MIxS_Sample)

# save step as file for IPT
split_table <- data.frame(ExtData_MIxS_Sample)
write.xlsx(split_table,
           file="./data/IPT_ExtData_MIxS_Sample.xlsx",
           sheetName = "ExtData_MIxS_Sample", col.names=TRUE, row.names=FALSE, showNA=FALSE, append = FALSE)


#-------------------------------------------------------
# 2e. mapping to (Extended?) Measurement Or Facts Extention
#-------------------------------------------------------

library(reshape2)

# Cols:
# measurementID
# measurementType
# measurementValue


# Select fields from master table
ExtData_EMoF <- select(flatDataMaster,
                       "occurrenceID" = "occurrence.sequenceID",
                       "waterBodyID" = "locality.waterBodyID",
                       "readName" = starts_with("occurrence.read"),
                       "consensusSequence" = "sequence_ASV.GGBN-A:consensusSequence")

# table details
tableSummary(ExtData_EMoF)
ExtData_EMoF

# Rearrange value columns into type-vale pairs in two columns
# ExtData_EMoF <- melt(ExtData_EMoF, 
#                      id=c("occurrenceID"), 
#                      measure=c("readName"),
#                      variable.name="measurementType", 
#                      value.name="measurementValue")
ExtData_EMoF <- ExtData_EMoF %>% melt(id=c("occurrenceID"),
                      measure=c("readName", "waterBodyID", "consensusSequence"),
                      variable.name="measurementType",
                      value.name="measurementValue") %>%
  distinct() %>%
  arrange(occurrenceID)

# Remove all duplicate rows
# ExtData_EMoF <- distinct(ExtData_EMoF)

# Order by key field (just for checking)
# ExtData_EMoF <- ExtData_EMoF[order(ExtData_EMoF$occurrenceID),]

# table details
tableSummary(ExtData_EMoF)
ExtData_EMoF


# save step as file for testing
split_table <- data.frame(ExtData_EMoF)
write.xlsx(split_table,
           file="./data/IPT_ExtData_EMoF.xlsx",
           sheetName = "IPT_ExtData_EMoF", col.names=TRUE, row.names=FALSE, showNA=FALSE, append = FALSE)


#see 
# melt.data.frame {reshape2} etc
# google, "r rearrange data use column name for name and value for value"
# https://aberdeenstudygroup.github.io/studyGroup/lessons/SG-T1-GitHubVersionControl/VersionControl/

# as per this version:
# Publishing Status
# 2019-10-04 11:09:43
# Publishing version #1.0 of resource ga-test-9 failed: 
# Archive generation for resource ga-test-9 failed: Can't validate 
# DwC-A for resource ga-test-9. Each line must have a occurrenceID, 
# and each occurrenceID must be unique (please note comparisons are 
# case insensitive)

# Publishing Status
# 2019-10-04 12:01:04
# Publishing version #1.0 of resource ga-test-9 failed: Archive generation for resource ga-test-9 failed: 
# Can't validate DwC-A for resource ga-test-9. Each line must have a occurrenceID, and each occurrenceID 
# must be unique (please note comparisons are case insensitive)

