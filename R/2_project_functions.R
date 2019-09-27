
# ---------------------------------------------------
# Count all columns, rows, values, unique values and NAs for every column in a table.
# Currently all columns.
# ---------------------------------------------------
tableSummary <- function(theTable, exclude, include){
  
  # Get number of columns
  column_count = ncol(theTable)
  
  # Collect various row counts
  row_count <- sapply(theTable, function(x) length(x))
  value_count <- sapply(theTable, function(x) length(x[!is.na(x)]))
  unique_values <- sapply(theTable, function(x) length(unique(x[!is.na(x)])))
  NA_count <- sapply(theTable, function(x) length(x[is.na(x)]))
  
  # Merge results and transpose
  columnSummary <- rbind(row_count, value_count, NA_count, unique_values) %>% t

  # Print as-is
  tableName <- trimws(deparse(substitute(theTable)), which="both")
  
  # print(paste("Table: ",tableName,", Column count: ",column_count, sep=""), quote=FALSE)
  cat(paste("Table: ",tableName,"\nColumn count: ",column_count, "\n", sep=""))
  print(columnSummary)
  
  
  # print as data frame
  # columnSummary <- as.data.frame(columnSummary)
  # print.data.frame(columnSummary, max = NULL)
  #....
}
