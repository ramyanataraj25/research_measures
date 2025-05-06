setwd("/Users/christine/NTR/Toolkit")
load("/Users/christine/NTR/Toolkit/Toolkit_v2.0.RData")
source("/Users/christine/research_measures/src/Transcription_Converter.R")
pronunciations <- read.csv("pronunciations.csv")

# Convert IPA pronunciations to toolkit format
pronunciations$toolkit_pron <- sapply(pronunciations$toolkit_pron, ipa_to_inhouse)

# Define grain sizes we want to map
grain_sizes <- list(
    "PG" = "_PG",
    "ONC" = "_ONC",
    "OC" = "_OC",
    "OR" = "_OR"
)

# Your existing parameters
levels <- c("PG", "OR", "ONC", "OC")
table_options <- list(
  PG = c("all_tables_PG", "all_tables_PG_noposition", "all_tables_PG_freq", "all_tables_PG_freq_noposition"),
  OR = c("all_tables_OR", "all_tables_OR_noposition", "all_tables_OR_freq", "all_tables_OR_freq_noposition"),
  ONC = c("all_tables_ONC", "all_tables_ONC_noposition", "all_tables_ONC_freq", "all_tables_ONC_freq_noposition"),
  OC = c("all_tables_OC", "all_tables_OC_noposition", "all_tables_OC_freq", "all_tables_OC_freq_noposition")
)
measures <- c("PG", "GP", "PG_freq", "P_freq", "G_freq")

# Create dataframe to store results
results_df <- data.frame(
  spelling = pronunciations$X0,
  pronunciation = pronunciations$toolkit_pron,
  stringsAsFactors = FALSE
)

# Process each pseudoword
cat("Processing", nrow(pronunciations), "pseudowords...\n")

# First, extract phonemes and graphemes for each grain size
for (i in 1:nrow(pronunciations)) {
  word <- pronunciations$X0[i]
  pron <- pronunciations$toolkit_pron[i]
  
  cat("Processing word", i, "of", nrow(pronunciations), ":", word, "(", pron, ")\n")
  
  # Process each grain size
  for (grain in names(grain_sizes)) {
    tryCatch({
      # Get mapping using map_value
      table_name <- paste0("all_tables_", grain)
      mapping_result <- map_value(word, pron, grain, get(table_name))
      
      if (is.list(mapping_result) && length(mapping_result) > 0) {
        df <- mapping_result[[1]]
        
        if (is.data.frame(df) && nrow(df) >= 2) {
          # Extract phonemes (row 1) and graphemes (row 2)
          phonemes <- as.character(df[1, ])
          graphemes <- as.character(df[2, ])
          
          # Remove any NA column names
          valid_cols <- !is.na(names(df))
          phonemes <- phonemes[valid_cols]
          graphemes <- graphemes[valid_cols]
          
          # Store in results
          results_df[i, paste0(grain, "_phonemes")] <- paste(phonemes, collapse = "|")
          results_df[i, paste0(grain, "_graphemes")] <- paste(graphemes, collapse = "|")
          
          cat("  Added", grain, "units:", paste(phonemes, collapse = "|"), "/", paste(graphemes, collapse = "|"), "\n")
        }
      }
    }, error = function(e) {
      cat("  Error mapping", grain, "units:", conditionMessage(e), "\n")
      results_df[i, paste0(grain, "_phonemes")] <- NA
      results_df[i, paste0(grain, "_graphemes")] <- NA
    })
  }
}

# Then, calculate all the statistical measures for each pseudoword
for (i in 1:nrow(pronunciations)) {
  word <- pronunciations$X0[i]
  pron <- pronunciations$toolkit_pron[i]
  
  cat("Processing measures for word:", word, "\n")
  
  for (level in levels) {
    level_tables <- table_options[[level]]
    
    for (table_name in level_tables) {
      table_data <- get(table_name)
      
      for (measure in measures) {
        tryCatch({
          # Map and summarize
          mapped_pseudoword <- map_value(word, pron, level, table_data)
          summary <- summarize_words(mapped_pseudoword, measure)
          
          if (!is.null(summary)) {
            # Extract measure values (skip spelling and pronunciation)
            measure_cols <- names(summary)[!(names(summary) %in% c("spelling", "pronunciation"))]
            
            for (col in measure_cols) {
              # Create column name with prefix
              col_prefix <- gsub("^all_tables_", "", table_name)
              if (col_prefix %in% c("PG", "OR", "ONC", "OC")) {
                col_prefix <- paste0(col_prefix, "_default")
              }
              col_name <- paste(col_prefix, measure, col, sep = ".")
              
              # Add to results
              results_df[i, col_name] <- summary[[col]]
            }
          }
        }, error = function(e) {
          cat("  Error with", level, table_name, measure, ":", conditionMessage(e), "\n")
        })
      }
    }
  }
}

# Write results to CSV
write.csv(results_df, "/Users/christine/research_measures/src/pseudoword_measures.csv", row.names = FALSE)

# Print debug info
cat("\nColumns in pseudoword_measures.csv:\n")
phoneme_cols <- grep("_phonemes", colnames(results_df), value = TRUE)
grapheme_cols <- grep("_graphemes", colnames(results_df), value = TRUE)
cat("Phoneme columns:", length(phoneme_cols), "\n")
print(phoneme_cols)
cat("Grapheme columns:", length(grapheme_cols), "\n")
print(grapheme_cols)

cat("\nProcessing complete!\n")

### TESTING
summary <- summarize_words(map_value("oosh", "US", "PG", all_tables_PG), "PG")
pw_spell("s3rrm", level = "PG", tables=all_tables_PG)
summarize_words(map_value("serrm", "s3rrm", "PG", all_tables_PG), "PG")
pw_spell("s3rm", level = "PG", tables=all_tables_PG)
summarize_words(map_value("cerm", "s3rm", "PG", all_tables_PG), "PG")
summarize_words(map_value("cerm", "k3rm", "PG", all_tables_PG), "PG")
summarize_words(map_value("shrirr", "Sr3r", "PG", all_tables_PG), "PG")