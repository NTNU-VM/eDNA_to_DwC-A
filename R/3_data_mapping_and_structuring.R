library(tidyverse)
library(xlsx)

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



#=========================================================================
# 1. De-normalise all data into one table
#=========================================================================

#-------------------------------------------------------
# 1a.  Add locality to waterSample
#-------------------------------------------------------

# Pre-join table stats
tableSummary(locality)
tableSummary(waterSample)

# Rename locality fields before joining
locality_rename <- locality %>%
  select(locality_locality = locality,
         everything())
tableSummary(locality_rename)

# Rename waterSample fields before joining
waterSample_rename <- waterSample %>%
  select(waterSample_eventId = eventID,
         waterSample_fieldNumber = fieldNumber,
         waterSample_locality = locality,
         waterSample_materialSampleID = materialSampleID,
         everything())
tableSummary(waterSample_rename)

# stripped out duplicates from locality table to make this join work. Needs tweaked if likely to be duplicates.
locality_waterSample <- left_join(waterSample_rename,locality_rename,
                                  by = c("waterSample_locality" = "locality_locality"))

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

# Rename fields before joining
extraction_rename <- extraction %>%
  select(extraction_eventId = eventID,
         extraction_parentEventID = parentEventID,
         extraction_fk_fieldNumber = fk_fieldNumber,
         extraction_materialSampleID = materialSampleID,
         everything())
tableSummary(extraction_rename)

all_and_extraction <- left_join(locality_waterSample, extraction_rename, 
                                by = c("waterSample_fieldNumber" = "extraction_fk_fieldNumber"))
# Joined table stats
tableSummary(all_and_extraction)

# save step as file for testing
combinedTables <- data.frame(all_and_extraction)
write.xlsx(combinedTables, 
           file="./data/2_all_and_extraction.xlsx", 
           sheetName = "Combined Sheets", col.names=TRUE, row.names=FALSE, showNA=FALSE, append = FALSE)


## NEXT....

# #-------------------------------------------------------
# # 1c.  Add amplification
# #-------------------------------------------------------
# # Pre-join table stats
# tableSummary(amplification)
# 
# all_and_amplification <- left_join(all_and_extraction, amplification,
#                                    by = c("extractionNumber" = "fk_extractionNumber"))
# # Joined table stats
# tableSummary(all_and_amplification)
# 
# combined_tables <- data.frame(all_and_amplification)
# write.xlsx(combined_tables, 
#            file="./data/3_all_and_amplification.xlsx", 
#            sheetName = "Combined Sheets", col.names=TRUE, row.names=FALSE, showNA=FALSE, append = FALSE)
# 
# 
# #-------------------------------------------------------
# # 1d.  Add sequencing
# #-------------------------------------------------------
# # Pre-join table stats
# tableSummary(sequencing)
# 
# all_and_sequencing <- left_join(all_and_amplification, sequencing, 
#                                 by = c("amplificationNumber" = "fk_amplificationNumber"))
# # Joined table stats
# tableSummary(all_and_sequencing)
# 
# combined_tables <- data.frame(all_and_sequencing)
# write.xlsx(combined_tables, 
#            file="./data/4_all_and_sequencing.xlsx", 
#            sheetName = "Combined Sheets", col.names=TRUE, row.names=FALSE, showNA=FALSE, append = FALSE)
# 
# 
# #-------------------------------------------------------
# # 1e.  Add occurrence
# #-------------------------------------------------------
# # Pre-join table stats
# tableSummary(occurrence)
# 
# all_and_occurrence <- left_join(all_and_sequencing, occurrence, 
#                                 by = c("sequencingNumber" = "fk_sequencingNumber"))
# # Joined table stats
# tableSummary(all_and_occurrence)
# 
# combined_tables <- data.frame(all_and_occurrence)
# write.xlsx(combined_tables, 
#            file="./data/5_all_and_occurrence.xlsx", 
#            sheetName = "Combined Sheets", col.names=TRUE, row.names=FALSE, showNA=FALSE, append = FALSE)
# 
# 
# #-------------------------------------------------------
# # 1e.  Add sequence_ASV
# #-------------------------------------------------------
# # Pre-join table stats
# tableSummary(sequence_ASV)
# 
# all_and_sequence_ASV <- left_join(all_and_occurrence, sequence_ASV, 
#                                 by = "sequenceNumber")
# # Joined table stats
# tableSummary(all_and_sequence_ASV)
# 
# combined_tables <- data.frame(all_and_sequence_ASV)
# write.xlsx(combined_tables, 
#            file="./data/6_all_and_sequence_ASV.xlsx", 
#            sheetName = "Combined Sheets", col.names=TRUE, row.names=FALSE, showNA=FALSE, append = FALSE)
# 
# # ignore below for now..
# 
# 
# 
# 
# # This xlsx file maps well to the DwC-A core Event
# # see https://data.gbif.no/ipt-test/manage/resource?r=ga-test-7
# # Only one field (sampleNumber) left unmapped; sampleNumber is embedded as the 2nd element in fieldNumber.
# 
# # Alternative joins and method
# #location_and_waterSample_to_Event_core <- inner_join(waterSample,locality)
# #location_and_waterSample_to_Event_core <- right_join(waterSample,locality)
# #location_and_waterSample_to_Event_core <- full_join(waterSample,locality)
# # merge(waterSample,locality, by = by.x = "locality", by.y = "locality",
# #       by.x = by, by.y = by, all = FALSE, all.x = all, all.y = all,
# #       sort = TRUE, suffixes = c(".x",".y"), no.dups = TRUE,
# #       incomparables = NULL, ...)
# 
# 
# # Rename fields before joining
# extraction_to_event_core <- extraction %>%
#   select(extraction_eventId = eventID,
#          extraction_parentEventID = parentEventID,
#          extraction_fk_fieldNumber = fk_fieldNumber,
#          extraction_materialSampleID = materialSampleID,
#          everything())
# tableSummary(extraction)
# tableSummary(extraction_to_event_core)
# 
# 
# # save step as file for testing
# write.xlsx(data.frame(extraction), file="./data/extraction_to_event_core.xlsx", 
#            sheetName = "extraction", col.names=TRUE, row.names=FALSE, showNA=FALSE, append = FALSE)
# 
#  
# # ...... 
# 
# # event_core_take1 <- bind_rows(location_and_waterSample_to_Event_core,extraction_to_event_core)
# 
# # 1b) reorder columns
# event_core_take1 <- event_core_take1 %>% 
#   select(eventID,parentEventID,locality,eventDate,samplingProtocol)
# 
# 
# 
# # 2) creating the occurrence extention
# 
# 
# #location_and_waterSample_to_Event_core <- left_join(waterSample,locality)
# 
# # save step as file for testing
# #combinedTables <- data.frame(location_and_waterSample_to_Event_core)
# 
# # Save occurrence table for testing
# # as-is
# write.xlsx(data.frame(occurrence), 
#            file="./data/occurrence.xlsx", 
#            sheetName = "occurrence", col.names=TRUE, row.names=FALSE, showNA=FALSE, append = FALSE)
# 
# #After removing all "No match" rows.
# matchingOccurrences <- occurrence %>% filter(!str_detect(matchingScientificName, "No match"))
# #head(matchingOccurrences)
# 
# write.xlsx(data.frame(matchingOccurrences), 
#            file="./data/matchingOccurrences.xlsx", 
#            sheetName = "occurrence", col.names=TRUE, row.names=FALSE, showNA=FALSE, append = FALSE)
# 
# 
# 
# #=========================================================================
# # 2. Split into tables for the occurrence core and each core extension
# #=========================================================================
# 
# 
# #-------------------------------------------------------
# # 2a. Mapping to Occurrence Core
# #-------------------------------------------------------
# extraction_and_amplification <- left_join(extraction, amplification, by = c("extractionNumber" = "fk_extractionNumber"))
# 
# # save step as file for testing
# # combinedTables <- data.frame(extraction_and_amplification)
# # count(combinedTables)
# # write.xlsx(combinedTables, 
# #            file="./data/extraction_and_amplification.xlsx", 
# #            sheetName = "extraction_&_amplification", col.names=TRUE, row.names=FALSE, showNA=FALSE, append = FALSE)
# 
# # extractions have to be registered as events, so merge extraction_and_amplification with Event core table
# extraction_and_amplification_to_Event_core <- right_join(location_and_waterSample_to_Event_core, 
#                                                         extraction_and_amplification)
# count(extraction_and_amplification_to_Event_core)
# write.xlsx(combinedTables,
#            file="./data/extraction_and_amplification_to_Event_core.xlsx",
#            sheetName = "location-to-amplification", col.names=TRUE, row.names=FALSE, showNA=FALSE, append = FALSE)
# 
# #-------------------------------------------------------
# # 2b. mapping to GGBN Preparation Extension
# #-------------------------------------------------------
# 
# 
# #-------------------------------------------------------
# # 2c. mapping to GGBN Amplification Extension
# #-------------------------------------------------------
# 
# 
# #-------------------------------------------------------
# # 2d. mapping to MIxS Sample Extension
# #-------------------------------------------------------
# 
# 
# #-------------------------------------------------------
# # 2e. mapping to Extended Measurement Or Facts Extention
# #-------------------------------------------------------
# 
# 
