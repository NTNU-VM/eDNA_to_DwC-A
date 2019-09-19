# download data from googlesheet

library(googlesheets)

# register worksheet
# eDNA_sheet <- gs_title("GBIF eDNA record format")
eDNA_sheet <- gs_title("GBIF eDNA record format - modified")

# download individual sheets as dataframes
# locality <- gs_read(ss=eDNA_sheet, ws = "locality")
# waterSample <- gs_read(ss=eDNA_sheet, ws = "waterSample")
# extraction <- gs_read(ss=eDNA_sheet, ws = "extraction")
# amplification <- gs_read(ss=eDNA_sheet, ws = "amplification")
# sequencing <- gs_read(ss=eDNA_sheet, ws = "sequencing")
# occurrence <- gs_read(ss=eDNA_sheet, ws = "occurrence")
# sequence <- gs_read(ss=eDNA_sheet, ws = "sequence/AVS")

# save files to local cache
# dir.create("./data",showWarnings=FALSE)
# saveRDS(locality,"./data/locality.rds")
# saveRDS(waterSample,"./data/waterSample.rds")
# saveRDS(extraction,"./data/extraction.rds")
# saveRDS(amplification,"./data/amplification.rds")
# saveRDS(sequencing,"./data/sequencing.rds")
# saveRDS(occurrence,"./data/occurrence.rds")
# saveRDS(sequence,"./data/sequence.rds")


# Download and save each sheet before downloading next.
# - to try and get round "Too Many Requests (RFC 6585) (HTTP 429)" error
dir.create("./data",showWarnings=FALSE)

locality <- gs_read(ss=eDNA_sheet, ws = "locality")
saveRDS(locality,"./data/locality.rds")

waterSample <- gs_read(ss=eDNA_sheet, ws = "waterSample")
saveRDS(waterSample,"./data/waterSample.rds")

extraction <- gs_read(ss=eDNA_sheet, ws = "extraction")
saveRDS(extraction,"./data/extraction.rds")

amplification <- gs_read(ss=eDNA_sheet, ws = "amplification")
saveRDS(amplification,"./data/amplification.rds")

sequencing <- gs_read(ss=eDNA_sheet, ws = "sequencing")
saveRDS(sequencing,"./data/sequencing.rds")

occurrence <- gs_read(ss=eDNA_sheet, ws = "occurrence")
saveRDS(occurrence,"./data/occurrence.rds")

sequence <- gs_read(ss=eDNA_sheet, ws = "sequence/AVS")
saveRDS(sequence,"./data/sequence.rds")
