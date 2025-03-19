setwd("/Users/christine/NTR/Toolkit")
load("/Users/christine/NTR/Toolkit/Toolkit_v2.0.RData")
pronunciations <- read.csv("pronunciations.csv")

levels <- c("PG", "OR", "ONC", "OC")
table_options <- list(
  PG = c("all_tables_PG", "all_tables_PG_noposition", "all_tables_PG_freq", "all_tables_PG_freq_noposition"),
  OR = c("all_tables_OR", "all_tables_OR_noposition", "all_tables_OR_freq", "all_tables_OR_freq_noposition"),
  ONC = c("all_tables_ONC", "all_tables_ONC_noposition", "all_tables_ONC_freq", "all_tables_ONC_freq_noposition"),
  OC = c("all_tables_OC", "all_tables_OC_noposition", "all_tables_OC_freq", "all_tables_OC_freq_noposition")
)
measures <- c("PG", "GP", "PG_freq", "P_freq", "G_freq")

results_list <- list()

for (i in 1:nrow(pronunciations)) {
  word <- pronunciations$X0[i]
  pron <- pronunciations$toolkit_pron[i]
  
  word_results <- list(spelling = word, pronunciation = pron)
  
  for (level in levels) {
    level_tables <- table_options[[level]]
    
    for (table_name in level_tables) {
      table_data <- get(table_name)
      
      for (measure in measures) {
        mapped_pseudoword <- map_value(word, pron, level, table_data)
        summary <- summarize_words(mapped_pseudoword, measure)
        
        summary <- summary[ , !(names(summary) %in% c("spelling", "pronunciation"))]
        
        col_prefix <- gsub("^all_tables_", "", table_name)
        if (col_prefix %in% c("PG", "OR", "ONC", "OC")) {
          col_prefix <- paste0(col_prefix, "_default")
        }
        col_prefix <- paste(col_prefix, measure, sep = "_")
    
        summary <- setNames(as.list(summary), paste(col_prefix, names(summary), sep = "."))
        
        word_results <- c(word_results, summary)
      }
    }
  }
  results_list[[i]] <- word_results
}

results_df <- do.call(rbind.data.frame, results_list)
write.csv(results_df, "pseudoword_measures.csv", row.names = FALSE)


### TESTING
summary <- summarize_words(map_value("oosh", "US", "PG", all_tables_PG), "PG")
pw_spell("s3rrm", level = "PG", tables=all_tables_PG)
summarize_words(map_value("serrm", "s3rrm", "PG", all_tables_PG), "PG")
pw_spell("s3rm", level = "PG", tables=all_tables_PG)
summarize_words(map_value("cerm", "s3rm", "PG", all_tables_PG), "PG")
summarize_words(map_value("cerm", "k3rm", "PG", all_tables_PG), "PG")
summarize_words(map_value("shrirr", "Sr3r", "PG", all_tables_PG), "PG")
