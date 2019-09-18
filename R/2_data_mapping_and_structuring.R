
library(tidyverse)

locality <- readRDS("./data/locality.rds")
waterSample <- readRDS("./data/waterSample.rds")
extraction <- readRDS("./data/extraction.rds")


#.....................................................
# 1. mapping to DwC-A occurrence and event tables
#-------------------------------------------------------

# 1) creating the event-core
# 1a) de-normalizing and extracting fields that should go to the event core 

location_and_waterSample_to_Event_core <- left_join(waterSample,locality)
extraction_to_event_core <- extraction %>% 
  select(eventID,
         parentEventID,
         fieldNumber=extractionNumber,
         samplingProtocol=extractionMethod)

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

