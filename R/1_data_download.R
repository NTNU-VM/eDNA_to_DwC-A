

library(googlesheets)
library(dplyr)

# register worksheet
eDNA_sheet <- gs_title("GBIF eDNA record format")

# download individual sheets as dataframes
locality <- gs_read(ss=eDNA_sheet, ws = "locality")
waterSample <- gs_read(ss=eDNA_sheet, ws = "waterSample")

