library(tidyverse)
library(xlsx)

source("R/1_data_download.R", local = TRUE)

locality <- readRDS("./data/locality.rds")
waterSample <- readRDS("./data/waterSample.rds")
extraction <- readRDS("./data/extraction.rds")
amplification <- readRDS("./data/amplification.rds")
sequencing <- readRDS("./data/sequencing.rds")
occurrence <- readRDS("./data/occurrence.rds")
sequence <- readRDS("./data/sequence.rds")


#.....................................................
# 1. mapping to DwC-A occurrence and event tables
#-------------------------------------------------------

# 1) creating the event-core
# 1a) de-normalizing and extracting fields that should go to the event core 

# stripped out duplicates from locality table to make this join work. Needs tweaked if there are to be duplicates.
location_and_waterSample_to_Event_core <- left_join(waterSample,locality)

# save step as file for testing
combinedTables <- data.frame(location_and_waterSample_to_Event_core)
write.xlsx(combinedTables, 
           file="./data/location_and_waterSample_to_Event_core.xlsx", 
           sheetName = "Combined Sheets", col.names=TRUE, row.names=FALSE, showNA=FALSE, append = FALSE)

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

