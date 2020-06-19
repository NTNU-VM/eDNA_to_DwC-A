#=========================================================================
# Functions script for spreadsheet-to-IPT pipeline prototype.
# - Run the main script, 3.
# 
# Primarily for processing data files and outputting summary data on these for checking.
#=========================================================================

# Packages
library(crayon)

# ---------------------------------------------------
# tableSummary
# 
# Count all columns, rows, values, unique values and NAs for every column in a table.
# Currently all columns.
# 
# Params
#  theTable - the table or dataframe to be summarised
#  exclude  - list of columns to include (currently unused)
#  include  - list of columns to exclude (currently unused)
#             Default = all columns.
# ---------------------------------------------------
tableSummary <- function(theTable, exclude, include){
  
  # Get number of columns
  column_count = ncol(theTable)
  
  # Collect various row counts
  RowCount <- sapply(theTable, function(x) length(x))
  ValueCount <- sapply(theTable, function(x) length(x[!is.na(x)]))
  UniqueValues <- sapply(theTable, function(x) length(unique(x[!is.na(x)])))
  NA_Count <- sapply(theTable, function(x) length(x[is.na(x)]))
  
  # Merge results and transpose
  columnSummary <- rbind(RowCount, ValueCount, NA_Count, UniqueValues) %>% t
  
  # Get tablename string
  tableName <- trimws(deparse(substitute(theTable)), which="both")
  
  # Count number of duplicated rows
  duplicates <- sum(duplicated(theTable), na.rm = TRUE)
  
  # Define output formats
  ok <- green$bold
  warn <- red$bold
  
  # Line for ease of reading
  lineString <- "------------------------------------------------------------------------"
  
  summaryString <- paste0("\n", lineString,
                          "\nTable: ", ok(tableName),
                          "\nColumn count: ", ok(column_count))
  # Duplicate rows
  
  if(duplicates > 0){                        
    dupRowString <- paste0("\nDuplicate row count: ", warn(duplicates[1]))
  } else {                        
    dupRowString <- paste0("\nDuplicate row count: ", ok(duplicates[1]))
  }
  summaryString <- paste0(summaryString, dupRowString)
  
  # Duplicate column names
  
  # Get positions and count of duplicate colnames
  theColNames <- colnames(theTable)
  dupIndices <- which(duplicated(theColNames))
  dupColNameCount <- length(dupIndices)
  
  if(dupColNameCount > 0){
    # Show duplicate colname count
    dupColNameCountString <- paste0("\nDuplicate column name count: ", warn(dupColNameCount))
    
    # List the duplicate colnames
    dupColNames <- paste(theColNames[dupIndices], collapse=", ")
    dupColNamesString <- paste0("\nDuplicate column names: ", warn(dupColNames))
    
    # Add to report string
    summaryString <- paste0(summaryString, dupColNameCountString, dupColNamesString)
  } else {
    # Show duplicate colname count
    dupColNameCountString <- paste0("\nDuplicate column name count: ", ok(dupColNameCount))
    
    # Add to report string
    summaryString <- paste0(summaryString, dupColNameCountString)
  }
  
  cat(summaryString, "\n", sep="")
  
  # Summary of columns 
  
  cat(paste0("Column stats:", "\n"))
  print(columnSummary)
  cat(paste0(lineString, "\n"))
  
}


# ---------------------------------------------------
# saveAsExcel
# 
# Save table/dataframe to excel
# 
#   dir       - destination for new excel file
#   tableName - name of new excel file
#   theTable  - the table or dataframe to be converted
# ---------------------------------------------------
saveAsExcel <- function(dir, tableName, theTable){
  
  # cast to dataframe
  tableToExcel <- data.frame(theTable)
  
  # set file name and path
  newFilePath <- paste0(dir, tableName, ".xlsx")
  
  # save as excel
  write.xlsx(tableToExcel,
             file = newFilePath,
             sheetName = tableName,
             col.names = TRUE,
             row.names = FALSE,
             showNA = FALSE,
             append = FALSE)
  
  # write.xlsx2(tableToExcel, 
  #             file = newFilePath,
  #             sheetName = tableName, 
  #             col.names = TRUE, 
  #             row.names = FALSE, 
  #             append = FALSE)
  
}
