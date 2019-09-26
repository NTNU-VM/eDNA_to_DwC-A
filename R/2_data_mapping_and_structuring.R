library(tidyverse)
library(xlsx)

source("R/1_data_download.R", local = TRUE)

locality <- readRDS("./data/locality.rds")
waterSample <- readRDS("./data/waterSample.rds")
extraction <- readRDS("./data/extraction.rds")
amplification <- readRDS("./data/amplification.rds")
sequencing <- readRDS("./data/sequencing.rds")
occurrence <- readRDS("./data/occurrence.rds")
sequence_ASV <- readRDS("./data/sequence_ASV.rds")


#.....................................................
# 1. mapping to DwC-A occurrence and event tables
#-------------------------------------------------------

# 1) creating the event-core
# 1a) de-normalizing and extracting fields that should go to the event core 

## Add locality to waterSample ##
# stripped out duplicates from locality table to make this join work. Needs tweaked if likely to be duplicates.
locality_waterSample <- left_join(waterSample,locality)
count(locality_waterSample)

# save step as file for testing
combined_tables <- data.frame(locality_waterSample)
write.xlsx(combined_tables, file="./data/1_locality_waterSample.xlsx", 
           sheetName = "Combined Sheets", col.names=TRUE, row.names=FALSE, showNA=FALSE, append = FALSE)


## Now add extraction ##
all_and_extraction <- left_join(locality_waterSample, extraction, 
                                by = c("eventID" = "parentEventID"))
count(all_and_extraction)

combinedTables <- data.frame(all_and_extraction)
write.xlsx(combinedTables, 
           file="./data/2_all_and_extraction.xlsx", 
           sheetName = "Combined Sheets", col.names=TRUE, row.names=FALSE, showNA=FALSE, append = FALSE)


## Now add amplification ##
all_and_amplification <- left_join(all_and_extraction, amplification, 
                                   by = c("extractionNumber" = "fk_extractionNumber"))
count(all_and_amplification)

combined_tables <- data.frame(all_and_amplification)
write.xlsx(combined_tables, 
           file="./data/3_all_and_amplification.xlsx", 
           sheetName = "Combined Sheets", col.names=TRUE, row.names=FALSE, showNA=FALSE, append = FALSE)


## Now add sequencing ##
all_and_sequencing <- left_join(all_and_amplification, sequencing, 
                                by = c("amplificationNumber" = "fk_amplificationNumber"))
count(all_and_sequencing)

combined_tables <- data.frame(all_and_sequencing)
write.xlsx(combined_tables, 
           file="./data/4_all_and_sequencing.xlsx", 
           sheetName = "Combined Sheets", col.names=TRUE, row.names=FALSE, showNA=FALSE, append = FALSE)


## Now add occurrence ##
all_and_occurrence <- left_join(all_and_sequencing, occurrence, 
                                by = c("sequencingNumber" = "fk_sequencingNumber"))
count(all_and_occurrence)

combined_tables <- data.frame(all_and_occurrence)
write.xlsx(combined_tables, 
           file="./data/5_all_and_occurrence.xlsx", 
           sheetName = "Combined Sheets", col.names=TRUE, row.names=FALSE, showNA=FALSE, append = FALSE)


## Now add sequence_ASV ##
all_and_sequence_ASV <- left_join(all_and_occurrence, sequence_ASV, 
                                by = "sequenceNumber")
count(all_and_sequence_ASV)

combined_tables <- data.frame(all_and_sequence_ASV)
write.xlsx(combined_tables, 
           file="./data/6_all_and_sequence_ASV.xlsx", 
           sheetName = "Combined Sheets", col.names=TRUE, row.names=FALSE, showNA=FALSE, append = FALSE)

# ignore below for now..




# This xlsx file maps well to the DwC-A core Event
# see https://data.gbif.no/ipt-test/manage/resource?r=ga-test-7
# Only one field (sampleNumber) left unmapped; sampleNumber is embedded as the 2nd element in fieldNumber.

# Alternative joins and method
#location_and_waterSample_to_Event_core <- inner_join(waterSample,locality)
#location_and_waterSample_to_Event_core <- right_join(waterSample,locality)
#location_and_waterSample_to_Event_core <- full_join(waterSample,locality)
# merge(waterSample,locality, by = by.x = "locality", by.y = "locality",
#       by.x = by, by.y = by, all = FALSE, all.x = all, all.y = all,
#       sort = TRUE, suffixes = c(".x",".y"), no.dups = TRUE,
#       incomparables = NULL, ...)


# extraction_to_event_core <- extraction %>%
#   select(eventID,
#          parentEventID,
#          fieldNumber = extractionNumber,
#          samplingProtocol = extractionMethod,
#          everything())

# save step as file for testing
write.xlsx(data.frame(extraction), file="./data/extraction_to_event_core.xlsx", 
           sheetName = "extraction", col.names=TRUE, row.names=FALSE, showNA=FALSE, append = FALSE)

 
# ...... 

# event_core_take1 <- bind_rows(location_and_waterSample_to_Event_core,extraction_to_event_core)

# 1b) reorder columns
event_core_take1 <- event_core_take1 %>% 
  select(eventID,parentEventID,locality,eventDate,samplingProtocol)



# 2) creating the occurrence extention


#location_and_waterSample_to_Event_core <- left_join(waterSample,locality)

# save step as file for testing
#combinedTables <- data.frame(location_and_waterSample_to_Event_core)

# Save occurrence table for testing
# as-is
write.xlsx(data.frame(occurrence), 
           file="./data/occurrence.xlsx", 
           sheetName = "occurrence", col.names=TRUE, row.names=FALSE, showNA=FALSE, append = FALSE)

#After removing all "No match" rows.
matchingOccurrences <- occurrence %>% filter(!str_detect(matchingScientificName, "No match"))
#head(matchingOccurrences)

write.xlsx(data.frame(matchingOccurrences), 
           file="./data/matchingOccurrences.xlsx", 
           sheetName = "occurrence", col.names=TRUE, row.names=FALSE, showNA=FALSE, append = FALSE)


#.....................................................
# 2. mapping to extentions
#-------------------------------------------------------
extraction_and_amplification <- left_join(extraction, amplification, by = c("extractionNumber" = "fk_extractionNumber"))

# save step as file for testing
# combinedTables <- data.frame(extraction_and_amplification)
# count(combinedTables)
# write.xlsx(combinedTables, 
#            file="./data/extraction_and_amplification.xlsx", 
#            sheetName = "extraction_&_amplification", col.names=TRUE, row.names=FALSE, showNA=FALSE, append = FALSE)

# extractions have to be registered as events, so merge extraction_and_amplification with Event core table
extraction_and_amplification_to_Event_core <- right_join(location_and_waterSample_to_Event_core, 
                                                        extraction_and_amplification)
count(extraction_and_amplification_to_Event_core)
write.xlsx(combinedTables,
           file="./data/extraction_and_amplification_to_Event_core.xlsx",
           sheetName = "location-to-amplification", col.names=TRUE, row.names=FALSE, showNA=FALSE, append = FALSE)


#.....................................................
# 2-a. mapping to eMoF extentions
#-------------------------------------------------------

#.....................................................
# 2-a. mapping to GGBN extentions .... 
#-------------------------------------------------------

