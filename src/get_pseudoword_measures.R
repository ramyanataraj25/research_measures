# Load required packages and data
setwd("/Users/ramyanataraj/Documents/Research/toolkit-2.0-main")
load("/Users/ramyanataraj/Documents/Research/toolkit-2.0-main/Toolkit_v2.0.RData")
source("/Users/ramyanataraj/Documents/Research/research_measures/src/Transcription_Converter.R")

# Read and convert pronunciations
pronunciations <- read.csv("pronunciations.csv")
pronunciations$toolkit_pron <- sapply(pronunciations$toolkit_pron, ipa_to_inhouse)

# Your existing parameters
levels <- c("PG", "OR", "ONC", "OC")
table_options <- list(
  PG = c("all_tables_PG", "all_tables_PG_noposition", "all_tables_PG_freq", "all_tables_PG_freq_noposition"),
  OR = c("all_tables_OR", "all_tables_OR_noposition", "all_tables_OR_freq", "all_tables_OR_freq_noposition"),
  ONC = c("all_tables_ONC", "all_tables_ONC_noposition", "all_tables_ONC_freq", "all_tables_ONC_freq_noposition"),
  OC = c("all_tables_OC", "all_tables_OC_noposition", "all_tables_OC_freq", "all_tables_OC_freq_noposition")
)
measures <- c("PG", "GP", "PG_freq", "P_freq", "G_freq")

# Add debug for two first words
if (nrow(pronunciations) >= 2) {
  cat("DEBUG: First two pseudowords:\n")
  cat("1.", pronunciations$X0[1], "pronounced as", pronunciations$toolkit_pron[1], "\n")
  cat("2.", pronunciations$X0[2], "pronounced as", pronunciations$toolkit_pron[2], "\n\n")
}

# Process each pseudoword and calculate measures
results_list <- list()

for (i in 1:nrow(pronunciations)) {
  word <- pronunciations$X0[i]
  pron <- pronunciations$toolkit_pron[i]
  
  cat("Processing word:", word, "with pronunciation:", pron, "\n")
  
  # Initialize results for this word
  word_results <- list(spelling = word, pronunciation = pron)
  
  # Calculate measures for each level and table
  for (level in levels) {
    level_tables <- table_options[[level]]
    
    for (table_name in level_tables) {
      table_data <- get(table_name)
      
      for (measure in measures) {
        # Try to get measures, with error handling
        tryCatch({
          mapped_pseudoword <- map_value(word, pron, level, table_data)
          summary <- summarize_words(mapped_pseudoword, measure)
          
          if (!is.null(summary)) {
            summary <- summary[, !(names(summary) %in% c("spelling", "pronunciation"))]
            
            col_prefix <- gsub("^all_tables_", "", table_name)
            if (col_prefix %in% c("PG", "OR", "ONC", "OC")) {
              col_prefix <- paste0(col_prefix, "_default")
            }
            col_prefix <- paste(col_prefix, measure, sep = "_")
            
            summary <- setNames(as.list(summary), paste(col_prefix, names(summary), sep = "."))
            word_results <- c(word_results, summary)
          }
        }, error = function(e) {
          cat("Error with", word, pron, level, table_name, measure, ":", conditionMessage(e), "\n")
        })
      }
    }
  }
  results_list[[i]] <- word_results
}

# Convert to dataframe and save
results_df <- do.call(rbind.data.frame, results_list)
write.csv(results_df, "pseudoword_measures.csv", row.names = FALSE)

# Create a simple mapped_units.csv
mapped_units_df <- data.frame(
  spelling = pronunciations$X0,
  mapped_units = pronunciations$toolkit_pron
)
write.csv(mapped_units_df, "mapped_units.csv", row.names = FALSE)

cat("Finished processing", nrow(pronunciations), "pseudowords\n")

### TESTING
summary <- summarize_words(map_value("oosh", "US", "PG", all_tables_PG), "PG")
pw_spell("s3rrm", level = "PG", tables=all_tables_PG)
summarize_words(map_value("serrm", "s3rrm", "PG", all_tables_PG), "PG")
pw_spell("s3rm", level = "PG", tables=all_tables_PG)
summarize_words(map_value("cerm", "s3rm", "PG", all_tables_PG), "PG")
summarize_words(map_value("cerm", "k3rm", "PG", all_tables_PG), "PG")
summarize_words(map_value("shrirr", "Sr3r", "PG", all_tables_PG), "PG")