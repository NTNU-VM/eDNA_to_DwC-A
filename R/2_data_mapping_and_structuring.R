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

# save step as file for checking
intermediate_step <- data.frame(location_and_waterSample_to_Event_core)
write.xlsx(intermediate_step, file="./data/location_and_waterSample_to_Event_core__left.xlsx", 
           sheetName = "Combined Sheets", col.names=TRUE, row.names=FALSE, showNA=FALSE, append = FALSE)

#location_and_waterSample_to_Event_core <- inner_join(waterSample,locality)
#location_and_waterSample_to_Event_core <- right_join(waterSample,locality)
#location_and_waterSample_to_Event_core <- full_join(waterSample,locality)

# Alternative join method
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

# save step as file for checking
write.xlsx(data.frame(extraction), file="./data/extraction_to_event_core.xlsx", 
           sheetName = "extraction", col.names=TRUE, row.names=FALSE, showNA=FALSE, append = FALSE)

 
# ...... 

event_core_take1 <- bind_rows(location_and_waterSample_to_Event_core,extraction_to_event_core)

# 1b) reorder columns
event_core_take1 <- event_core_take1 %>% 
  select(eventID,parentEventID,locality,eventDate,samplingProtocol)

# 2) creating the occurrence extention


#.....................................................
# 2-a. mapping to eMoF extantions
#-------------------------------------------------------

#.....................................................
# 2-a. mapping to GGBN extantions .... 
#-------------------------------------------------------

