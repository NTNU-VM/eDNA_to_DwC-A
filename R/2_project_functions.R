
# ---------------------------------------------------
# Count all columns, rows, values, unique values and NAs for every column in a table.
# Currently all columns.
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
  
  # Line for ease of reading
  lineString <- "------------------------"
  cat(paste("\n", lineString,
            "\nTable: ",tableName,
            "\nColumn count: ",column_count, 
            "\nDuplicate row count: ",duplicates[1], 
            "\n", sep=""))
  
  # Check for duplicate column names
  theColNames <- colnames(theTable)
  
  # Get positions and count of duplicate colnames
  dupIndices <- which(duplicated(theColNames))
  dupCount <- length(dupIndices)
  cat(paste("Duplicate column name count: ", dupCount, "\n", sep=""))

  if(dupCount > 0){
    # List the duplicate names
    dupColNames <- paste(theColNames[dupIndices], collapse=", ")
    cat(paste("Duplicate column names: ", dupColNames, ".\n", sep=""))
  }
  
  cat("\n")
  print(columnSummary)
  cat(lineString)
  
}
