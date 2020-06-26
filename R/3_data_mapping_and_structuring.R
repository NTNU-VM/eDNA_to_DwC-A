#=========================================================================
# Main script (of 3) for spreadsheet-to-IPT pipeline prototype.
# - Run this file.
# 
# Updated to correspond with updated MIxS extension: 
#   http://rs.gbif.org/sandbox/extension/mixs_sample_2019_10_04.xml
# which is included in this version of the data model (10/12/019):
#   "GBIF eDNA mappings v3.2":
#   https://docs.google.com/spreadsheets/d/1paJ20-bLQ0OdQBEsj0BzoX32mgcZVvZh85pqglu9MN0/edit#gid=1428619335
#   "GBIF eDNA record format":
#   https://docs.google.com/spreadsheets/d/1uVWOxjJZo0v4uS5L6h8F-1sV5zNs7L_v7g1pSE_o8mY/edit#gid=534272466
# 
# 
# This version joins tables (more or less) from right to left as presented in 
# the google sheet, "GBIF eDNA record format", above.
# 
# 
# Input requirements:
# One google worksheet with spreadsheets named as follows:
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
#   IPT_ExtData_MIxS_Sample.xlsx
#   IPT_MoF_Table.xlsx
# 
# File locations:
#   Raw data files:                       ./data/raw/
#   Processed files (intermediate steps): ./data/process/
#   Final output files:                   ./data/output/
#=========================================================================

# Packages
library(tidyverse)
library(xlsx)
library(uuid)
library(sqldf)

# For JSON functionality, use one of:
# library(rjson)
library(jsonlite)
# library(RJSONIO)

# Included script files
source("R/1_data_download.R", local = TRUE)
source("R/2_project_functions.R", local = TRUE)

#==================================================
# User options
#==================================================

# Output as excel after each table join
outputStepsExcel <- FALSE

# Strip out occurrences in raw data listed as "no match"
removeNoMatches <- TRUE
matchColumn     <- as.name("occurrence.matchingScientificName") # can't get this to work. see below.
noMatchString   <- "No match"

#==================================================



# For output during processing: for checking/testing
dir.create("./data/process", showWarnings=FALSE)

# For final output files
dir.create("./data/output", showWarnings=FALSE)


# Fetch the stored tables
locality <- readRDS("./data/raw/locality.rds")
waterSample <- readRDS("./data/raw/waterSample.rds")
extraction <- readRDS("./data/raw/extraction.rds")
amplification <- readRDS("./data/raw/amplification.rds")
sequencing <- readRDS("./data/raw/sequencing.rds")
occurrence <- readRDS("./data/raw/occurrence.rds")
sequence_ASV <- readRDS("./data/raw/sequence_ASV.rds")

# Possible future method-
# Create a lookup table with columns for:
#   1. table names
#   2. original column names with extension prefixes (as imported)
#   3. extensions only (inserting default strings for core fields)
#   4. cleaned column names (stripped of all and any prefixes)
# This allows changes to extension prefixes without having to alter the joins below.
# Can also be repurposed later to allow extensions to be defined here, 
# instead of as prefixes in data tables (a pain in the arse).
# 
# Create lookup table for column names and prefixes
# colNameLookup <
# 
# # Store column names and prefixes
# colNameLookup("locality")
# colNameLookup("waterSample")
# colNameLookup("extraction")
# colNameLookup("amplification")
# colNameLookup("sequencing")
# colNameLookup("occurrence")
# colNameLookup("sequence_ASV")


# Prefix all column names with table names to avoid clashes.
colnames(locality) <- paste("locality", colnames(locality), sep = ".")
colnames(waterSample) <- paste("waterSample", colnames(waterSample), sep = ".")
colnames(extraction) <- paste("extraction", colnames(extraction), sep = ".")
colnames(amplification) <- paste("amplification", colnames(amplification), sep = ".")
colnames(sequencing) <- paste("sequencing", colnames(sequencing), sep = ".")
colnames(occurrence) <- paste("occurrence", colnames(occurrence), sep = ".")
colnames(sequence_ASV) <- paste("sequence_ASV", colnames(sequence_ASV), sep = ".")

# TODO
# - Do checks on primary keys for duplicates
# - Generate uuids for eventID and parentEventIDs -DONE
# - UUIDgenerate() or UUIDgenerate(use.time = TRUE) ...
# - Develop persistence for UUIDs when a dataset is refreshed or re-imported with updates.

#=========================================================================
# 0. Generate UUIDs for GBIF's ID columns where needed
#    - eventID and parentEventID in waterSample and extraction tables
#    - materialSampleID in waterSample and extraction tables
#=========================================================================

#-------------------------------------------------------
# 0a.  Generate UUIDs for eventID and parentEventID in waterSample and extraction tables
#-------------------------------------------------------

# Table info (relevant cols only, to show full colnames)
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
# Use the natural P and F keys (waterSample_ID) to select waterSample.eventID values.
extraction$extraction.parentEventID[
  extraction$extraction.waterSample_ID == waterSample$waterSample.waterSample_ID
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

# Comment as appropriate:

# A. If extraction.materialSampleIDs are inherited from waterSample.materialSampleIDs, then:
extraction$extraction.materialSampleID[
  extraction$extraction.waterSample_ID == waterSample$waterSample.waterSample_ID
  ] = waterSample$waterSample.materialSampleID

# or B. If extraction samples have their own IDs, then:
# for(i in 1:length(waterSample$waterSample.materialSampleID)){
#   waterSample$waterSample.materialSampleID[i] <- UUIDgenerate()
# }


# Table info  (relevant cols only, to show full colnames)
head(waterSample %>% select(1:3,5,6))
head(extraction %>% select(1:4,6))
tableSummary(waterSample)
tableSummary(extraction)


#=========================================================================
# 1. De-normalise all data into one table
# 
# TODO - 
# reverse order:
# start with occurrence and include only records which correspond to 
# occurrences with scientific name matches. -DONE
#=========================================================================


#-------------------------------------------------------
# 1a.  Filter occurrence
#-------------------------------------------------------
# Pre-joined table stats
tableSummary(occurrence)
# head(occurrence)

# Remove all "No match" rows from occurrence.
# These can be included for GBIF later, but for now, removing
# them makes the dataset more manageable.
occurrence <- occurrence %>% filter(!str_detect(occurrence.matchingScientificName, "No match"))
# occurrence <- occurrence %>% filter(!str_detect(as.name(matchColumn), noMatchString))
# occurrence <- occurrence %>% filter(!str_detect(matchColumn, noMatchString))

tableSummary(occurrence)
head(occurrence)

# tableToExcel <- data.frame(all_and_occurrence)
if(outputStepsExcel){
  saveAsExcel(theTable = all_and_occurrence, tableName="1_occurrence", dir="./data/process/")
}

#-------------------------------------------------------
# 1b.  Add sequence_ASV
#-------------------------------------------------------
# Pre-joined table stats
tableSummary(sequence_ASV)

occurrence_and_sequence_ASV <- left_join(occurrence, sequence_ASV,
                                         by = c("occurrence.sequence_ASV_ID" = "sequence_ASV.sequence_ASV_ID"))

# Joined table stats
tableSummary(occurrence_and_sequence_ASV)

# tableToExcel <- data.frame(all_and_sequence_ASV)
if(outputStepsExcel){
  saveAsExcel(theTable = occurrence_and_sequence_ASV, tableName="2_occurrence_and_sequence_ASV", dir="./data/process/")
}

#-------------------------------------------------------
# 1c.  Add sequencing
#-------------------------------------------------------
# Pre-joined table stats
tableSummary(sequencing)

all_and_sequencing <- inner_join(sequencing, occurrence_and_sequence_ASV, 
                                 by = c("sequencing.sequencing_ID" = "occurrence.sequencing_ID"))

# Joined table stats
tableSummary(all_and_sequencing)
# head(all_and_sequencing)

# tableToExcel <- data.frame(all_and_sequencing)
if(outputStepsExcel){
  saveAsExcel(theTable = all_and_sequencing, tableName="3_all_and_sequencing", dir="./data/process/")
}

#-------------------------------------------------------
# 1d.  Add amplification
#-------------------------------------------------------
# Pre-joined table stats
tableSummary(amplification)

all_and_amplification <- inner_join(amplification, all_and_sequencing,
                                    by = c("amplification.sequencing_ID" = "sequencing.sequencing_ID"))

# Joined table stats
tableSummary(all_and_amplification)
# head(all_and_amplification)

# tableToExcel <- data.frame(all_and_amplification)
if(outputStepsExcel){
  saveAsExcel(theTable = all_and_amplification, tableName="4_all_and_amplification", dir="./data/process/")
}

#-------------------------------------------------------
# 1e.  Add extraction
#-------------------------------------------------------
# Pre-joined table stats
tableSummary(extraction)

all_and_extraction <- inner_join(extraction, all_and_amplification, 
                                 by = c("extraction.extraction_ID" = "amplification.extraction_ID"))

# Joined table stats
tableSummary(all_and_extraction)

# save step as file for testing
if(outputStepsExcel){
  saveAsExcel(theTable = all_and_extraction, tableName="5_all_and_extraction", dir="./data/process/")
}


#-------------------------------------------------------
# 1f.  Add waterSample
#-------------------------------------------------------

# Pre-joined table stats
tableSummary(waterSample)

# stripped out duplicates from locality table to make this join work. Needs tweaked if likely to be duplicates.
all_and_waterSample <- inner_join(waterSample, all_and_extraction, 
                                  by = c("waterSample.waterSample_ID" = "extraction.waterSample_ID"))

# Joined table stats
tableSummary(all_and_waterSample)

# save step as file for testing
if(outputStepsExcel){
  saveAsExcel(theTable = all_and_waterSample, tableName="6_all_and_waterSample", dir="./data/process/")
}



#-------------------------------------------------------
# 1g.  Add locality
#-------------------------------------------------------

# Pre-joined table stats
tableSummary(locality)

all_and_locality <- inner_join(locality, all_and_waterSample,
                               by = c("locality.locality_ID" = "waterSample.locality_ID"))

# save as rds for use in next steps
saveRDS(all_and_locality,"./data/process/all_and_locality.rds")

# Joined table stats
tableSummary(all_and_locality)

# save step as file for testing
if(outputStepsExcel){
  saveAsExcel(theTable = all_and_locality, tableName="7_all_and_locality", dir="./data/process/")
}


#-------------------------------------------------------
# 1h.  Now save as master file for next steps
#-------------------------------------------------------
# library(googledrive)

# save in R format
flatDataMaster <- readRDS("./data/process/all_and_locality.rds")

# Joined table stats
tableSummary(flatDataMaster)

#  Collect stats on cardinality of entities
# - get av/max of each entity grouped by ocurrence_ID..........


# SQL queries from Master (before this branch was copied over):

head(flatDataMaster %>% select("occurrence.occurrence_ID"), 20)

# =================================================================================

sqldf("SELECT count(*) as 'Unique occurrence IDs', avg(count) as 'Av freq of occurrence IDs'
      FROM
      (
        SELECT COUNT (*) AS Count
        FROM flatDataMaster
        GROUP BY `occurrence.occurrence_ID`
      ) as counts")

# Show frequency of first few occurrence.occurrence_IDs
sqldf("select `occurrence.occurrence_ID`, count(*) as 'count'
      from flatDataMaster
      group by `occurrence.occurrence_ID`
      order by `occurrence.occurrence_ID`
      limit 10")

# Show occurrence.occurrence_IDs which occur less or more than the modal frequency
sqldf("SELECT *
      FROM
      (
        SELECT `occurrence.occurrence_ID`, count(*) as 'count'
            FROM flatDataMaster
            GROUP BY `occurrence.occurrence_ID`
      )
      WHERE 'count' <> 4")

sqldf("SELECT count(*) as 'Unique amplification IDs', avg(count) as 'Av freq of amplification IDs'
      FROM
      (
        SELECT COUNT (*) AS count
        FROM flatDataMaster
        GROUP BY `amplification.amplification_ID`
      ) as counts")

# Count unique sequencing IDs
# (Need to use amplification.sequencing_ID because sequencing.sequencing_ID has been dropped during the join)
sqldf("SELECT count(*) as 'Unique sequencing IDs', avg(count) as 'Av freq of sequencing IDs'
      FROM
      (
        SELECT COUNT (*) AS count
        FROM flatDataMaster
        GROUP BY `amplification.sequencing_ID`
      ) as counts")

# =================================================================================





# Save as xlsx
saveAsExcel(theTable = flatDataMaster, tableName="flatDataMaster", dir="./data/process/")


# Lines from AF
# # event_core_take1 <- bind_rows(location_and_waterSample_to_Event_core,extraction_to_event_core)
# 
# # 1b) reorder columns
# event_core_take1 <- event_core_take1 %>%
#   select(eventID,parentEventID,locality,eventDate,samplingProtocol)

# To remove all "No match" rows.
# occurrence <- occurrence %>% filter(!str_detect(occurrence.matchingScientificName, "No match"))
# head(matchingOccurrences)



#=========================================================================
# 2. Split into tables for the occurrence core and each core extension
#=========================================================================


#-------------------------------------------------------
# 2a. Mapping to Occurrence Core
#-------------------------------------------------------


## - update this select() when field names are updated!
## BEWARE! matches() doesn't return an exact match:
##  eg matches("locality.waterBody") returns both
##  locality.waterBody AND locality.waterBodyID.
## So best just to list column names (can be quoted/unquoted)
coreOccurrenceTable <- select(flatDataMaster, 
                              locality.locationID,
                              locality.verbatimLocality,
                              locality.waterBody,
                              locality.decimalLatitude,
                              locality.decimalLongitude,
                              locality.geodeticDatum,
                              locality.habitat,
                              fieldNumber = waterSample.waterSample_ID,
                              waterSample.eventID,
                              waterSample.materialSampleID,
                              waterSample.eventDate,
                              waterSample.eventTime,
                              waterSample.sampleSizeValue,
                              waterSample.sampleSizeUnit,
                              waterSample.samplingProtocol,
                              waterSample.eventRemarks,
                              eventID_2 = extraction.eventID,
                              extraction.parentEventID,
                              materialSampleID_2 = extraction.materialSampleID,
                              extraction.preparations,
                              occurrence.occurrence_ID,
                              # catalogNumber = occurrence.occurrence_ID,
                              # recordNumber = occurrence.occurrence_ID,
                              occurrence.taxonID,
                              scientificNameID = occurrence.matchingScientificName,
                              occurrence.scientificName,
                              identificationReferences = occurrence.identificationReference,
                              occurrence.dateIdentified,
                              occurrence.identificationVerificationStatus,
                              occurrence.identificationRemarks,
                              occurrence.organismQuantity,
                              occurrence.organismQuantityType,
                              occurrence.basisOfRecord,
                              # occurrence.dcterms:type,
                              type = "occurrence.dcterms:type")

# 2a1 table details - initial column selection
tableSummary(coreOccurrenceTable)

# Remove duplicate rows
coreOccurrenceTable <- unique(coreOccurrenceTable)
# coreOccurrenceTable <- coreOccurrenceTable %>% distinct()

# 2a2 table details - duplicate rows removed
tableSummary(coreOccurrenceTable)


# save as rds
saveRDS(coreOccurrenceTable,"./data/process/coreOccurrenceTable.rds")

# save step as file for testing
saveAsExcel(theTable = coreOccurrenceTable, tableName="coreOccurrenceTable", dir="./data/process/")


# Remove all tablename prefixes to allow auto mapping in IPT
# Up to and inc "."
colnames(coreOccurrenceTable) <- gsub("^.*?\\.", "", colnames(coreOccurrenceTable))

# If necessary, also remove prefixes separated by colons:
# colnames(coreOccurrenceTable) <- gsub("^.*?\\:", "", colnames(coreOccurrenceTable))

# TODO - check for duplicate colnames - remove

# Refs
# https://stackoverflow.com/questions/45960269/removing-suffix-from-column-names-using-rename-all
# https://stackoverflow.com/questions/25991824/remove-all-characters-before-a-period-in-a-string

# 2a3 table details - all colname prefixes removed
tableSummary(coreOccurrenceTable)

# Sort alphabetically, with occurrence_ID first, for ease of checking
# coreOccurrenceTable <- coreOccurrenceTable %>% select(occurrence_ID, sort(names(.)))
coreOccurrenceTable <- select(coreOccurrenceTable,
                              occurrence_ID, 
                              sort(names(coreOccurrenceTable)))

# 2a4 table details - columns sorted
tableSummary(coreOccurrenceTable)

# save step as file for IPT
saveAsExcel(theTable = coreOccurrenceTable, tableName="IPT_coreOccurrenceTable", dir="./data/output/")

#-------------------------------------------------------
# 2b. mapping to GGBN Preparation Extension - no remaining fields for this extension.
#-------------------------------------------------------

# ## TODO 
# ## - Add eventID & parentEventID fields for linking.
# ## - update this select() when field names are updated!
# 
# ExtData_GGBN_Preparation <- select(flatDataMaster, 
#                               "occurrenceID" = "occurrence.sequenceID",
#                               starts_with("extraction.GGBN-P:"),
#                               "preparationDate" = "waterSample.eventDate")
# 
# # table details
# tableSummary(ExtData_GGBN_Preparation)
# 
# # save as rds
# saveRDS(ExtData_GGBN_Preparation,"./data/process/ExtData_GGBN_Preparation.rds")
# 
# # save step as file for testing
# saveAsExcel(theTable = ExtData_GGBN_Preparation, tableName="ExtData_GGBN_Preparation", dir="./data/process/")
# 
# # Remove all tablename and extension name prefixes to allow auto mapping in IPT
# # Up to and inc ":"
# colnames(ExtData_GGBN_Preparation) <- gsub("^.*?\\:", "", colnames(ExtData_GGBN_Preparation))
# tableSummary(ExtData_GGBN_Preparation)
# 
# # save step as file for IPT
# saveAsExcel(theTable = ExtData_GGBN_Preparation, tableName="IPT_ExtData_GGBN_Preparation", dir="./data/output/")

#-------------------------------------------------------
# 2c. mapping to GGBN Amplification Extension - only one field and this will be moved to another extension.
#-------------------------------------------------------

## TODO 
## - Add eventID & parentEventID fields for linking.
## - update this select() when field names are updated!

ExtData_GGBN_Amplification <- select(flatDataMaster,
                                     matches("occurrence.occurrence_ID"),
                                     matches("sequencing.geneticAccessionNumber"))

# table details - initial column selection
tableSummary(ExtData_GGBN_Amplification)

# save as rds
saveRDS(ExtData_GGBN_Amplification,"./data/process/ExtData_GGBN_Amplification.rds")

# save step as file for testing
saveAsExcel(theTable = ExtData_GGBN_Amplification, tableName="ExtData_GGBN_Amplification", dir="./data/process/")

# Remove all tablename and extension name prefixes to allow auto mapping in IPT
# Up to and inc "."
colnames(ExtData_GGBN_Amplification) <- gsub("^.*?\\.", "", colnames(ExtData_GGBN_Amplification))

# table details - colname prefixes removed
tableSummary(ExtData_GGBN_Amplification)

# save step as file for IPT
saveAsExcel(theTable = ExtData_GGBN_Amplification, tableName="IPT_ExtData_GGBN_Amplification", dir="./data/output/")

#-------------------------------------------------------
# 2d. mapping to MIxS Sample Extension
#-------------------------------------------------------

# MIxS values may exist as one or many per occurence.
#   1. If one per occurrence, store as normal using the MIxS extension.
#   2. If many per occurrence, store either as:
#     2.1. Multiple MIxS records per occurrence ID (is this permitted?) 
#         - probably can't because there's no field for the secondary entity (eg amplification)..
#     2.2. In JSON format, using standard MIxS names with the values
#     2.3. In the Measurement or Facts Extention

## TODO 
## - Add eventID & parentEventID fields for linking.
## - update this select() when field names are updated.

ExtData_MIxS_Sample <- select(flatDataMaster,
                              "occurrence.occurrence_ID",
                              "extraction.nucl_acid_ext",
                              "amplification.target_gene",
                              "amplification.target_subfragment",
                              "amplification.pcr_primers",
                              "amplification.pcr_cond",
                              "amplification.nucl_acid_amp",
                              "amplification.adapters",
                              "amplification.mid",
                              "sequencing.lib_const_meth",
                              "sequencing.seq_meth",
                              "sequencing.sop",
                              "sequencing.submitted_to_insdc",
                              "sequencing.investigation_type",
                              "sequencing.env_biome",
                              "sequencing.env_feature",
                              "sequencing.env_material",
                              "sequencing.env_package",
                              "occurrence.lib_size",
                              "sequence_ASV.sequence")

# table details initial column selection
tableSummary(ExtData_MIxS_Sample)

# save as rds
saveRDS(ExtData_MIxS_Sample,"./data/process/ExtData_MIxS_Sample.rds")

# save step as file for testing
saveAsExcel(theTable = ExtData_MIxS_Sample, tableName="ExtData_MIxS_Sample", dir="./data/process/")

# Remove all tablename and extension name prefixes to allow auto mapping in IPT
# Up to and inc "."
colnames(ExtData_MIxS_Sample) <- gsub("^.*?\\.", "", colnames(ExtData_MIxS_Sample))

# table details - colname prefixes removed
tableSummary(ExtData_MIxS_Sample)

# Sort columns alphabetically, with occurrence_ID first, for ease of checking
# ExtData_MIxS_Sample <- ExtData_MIxS_Sample %>% select(occurrence_ID, sort(names(.)))
ExtData_MIxS_Sample <- select(ExtData_MIxS_Sample, 
                              occurrence_ID, 
                              sort(names(ExtData_MIxS_Sample)))

# Remove duplicate rows
ExtData_MIxS_Sample <- unique(ExtData_MIxS_Sample)
# ExtData_MIxS_Sample <- ExtData_MIxS_Sample %>% distinct()

# table details - columns sorted
tableSummary(ExtData_MIxS_Sample)

# save step as file for IPT
saveAsExcel(theTable = ExtData_MIxS_Sample, tableName="IPT_ExtData_MIxS_Sample", dir="./data/output/")

#-------------------------------------------------------
# 2e. mapping to (Core/Extended) Measurement or Facts
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
# For now I will implement B. (Full data will be stored in Genbank and referenced from the GBIF records).


library(reshape2)

#see 
# melt.data.frame {reshape2} etc
# google, "r rearrange data use column name for name and value for value"
# https://aberdeenstudygroup.github.io/studyGroup/lessons/SG-T1-GitHubVersionControl/VersionControl/

# Basic cols to use for MoF:
# measurementID
# measurementType
# measurementValue

# Select fields from master table which are one-to-one with occurrence.
# This includes most entity IDs to show where the occurrences are coming from.
MoF_Table <- select(flatDataMaster,
                    "occurrence.occurrence_ID",
                    "locality.locality_ID",
                    "locality.waterBodyID",
                    "extraction.extraction_ID",
                    "extraction.preparationDate",
                    "amplification.amplification_ID",
                    "amplification.amplificationDate",
                    "amplification.amplificationStaff",
                    "amplification.amplificationSuccess",
                    "amplification.amplificationSuccessDetails",
                    "amplification.primerNameForward",
                    "amplification.primerReferenceCitationForward",
                    "amplification.primerReferenceLinkForward",
                    "amplification.primerNameReverse",
                    "amplification.primerReferenceCitationReverse",
                    "amplification.primerReferenceLinkReverse",
                    "occurrence.readName",
                    "occurrence.sequence_ASV_ID")

# table details - initial column selection (untransformed)
tableSummary(MoF_Table)
# MoF_Table

# save step as file for testing
saveAsExcel(theTable = MoF_Table, tableName="MoF_Table", dir="./data/process/")

# Remove all tablename prefixes to allow auto mapping in IPT,
# Up to and inc "."
colnames(MoF_Table) <- gsub("^.*?\\.", "", colnames(MoF_Table))


# table details - minus colname prefixes (untransformed)
tableSummary(MoF_Table)

# Sort alphabetically, with occurrence_ID first, for ease of checking
MoF_Table <- select(MoF_Table,
                    occurrence_ID,
                    sort(names(MoF_Table)))

# table details - columns sorted
tableSummary(MoF_Table)


# Rearrange value columns into type-value pairs in two columns, alongside a column for occurrence_ID,
# remove all duplicate rows,
# order by key field (for checking):

# MoF_Table <- melt(MoF_Table, 
#                      id=c("occurrenceID"), 
#                      measure=c("readName"),
#                      variable.name="measurementType", 
#                      value.name="measurementValue")
# MoF_Table <- distinct(MoF_Table)
# MoF_Table <- MoF_Table[order(MoF_Table$occurrenceID),]

# Alternative syntax
MoF_Table <- MoF_Table %>% 
  melt(id.vars=c("occurrence_ID"),
       measure=c("extraction_ID", "locality_ID", "preparationDate", "readName", "sequence_ASV_ID", "waterBodyID"),
       variable.name="measurementType",
       value.name="measurementValue") %>%
  distinct() %>%
  arrange(occurrence_ID)

# table details - transformed to three-column format
tableSummary(MoF_Table)

cat(paste("To illustrate MoF table structure:", "\n"))
head(MoF_Table, 10)

# save as file for IPT
saveAsExcel(theTable = MoF_Table, tableName="IPT_MoF_Table", dir="./data/output/")

#-------------------------------------------------------
# 2f. mapping many-to-occurrence records to JSON
#-------------------------------------------------------

# Currently Amplification records are the only entity n:1 with Occurrence.

# Select fields from master table which are one-to-one with occurrence.
# This includes most entity IDs to show where the occurrences are coming from.
JSON_Table <- select(flatDataMaster,
                     "occurrence.occurrence_ID",
                     "locality.locality_ID",
                     # "locality.waterBodyID",
                     "extraction.extraction_ID",
                     # "extraction.preparationDate",
                     "amplification.amplification_ID",
                     # "amplification.amplificationDate",
                     # "amplification.amplificationStaff",
                     # "amplification.amplificationSuccess",
                     # "amplification.amplificationSuccessDetails",
                     # "amplification.primerNameForward",
                     # "amplification.primerReferenceCitationForward",
                     # "amplification.primerReferenceLinkForward",
                     # "amplification.primerNameReverse",
                     # "amplification.primerReferenceCitationReverse",
                     # "amplification.primerReferenceLinkReverse",
                     "occurrence.readName",
                     "occurrence.sequence_ASV_ID")

JSON_Table <- slice(JSON_Table, 1:54)

# table details - first few rows only
tableSummary(JSON_Table)

theJSON <- toJSON(JSON_Table)

prettify(theJSON, indent = 3)

minify(theJSON)


# json_data <- fromJSON(paste(readLines(theJSON), collapse=""))
# str(json_data)
# mydf <- data.frame(json_data$resultSets$rowSet)
# colnames(mydf) <- unlist(json_data$resultSets$headers)

# 
# END OF SCRIPT
# 
# path.expand


