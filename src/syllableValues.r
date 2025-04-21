setwd("/Users/ramyanataraj/Documents/Research/toolkit-2.0-main")
load("/Users/ramyanataraj/Documents/Research/toolkit-2.0-main/Toolkit_v2.0.RData")
source("/Users/ramyanataraj/Documents/Research/research_measures/src/Transcription_Converter.R")

# Read and convert pronunciations
pronunciations <- read.csv("pronunciations.csv")
spellings <- wordlist_v2_0$spelling
pronunciations <- wordlist_v2_0$pronunciation
freq_weights <- wordlist_v2_0$freq

mapped_words_output_name <- "all_words"
made_tables_output_name <- "all_tables"
mapped_values_output_name <- "scored_words"

grain_sizes <- list(
    "PG" = "_PG",
    "ONC" = "_ONC",
    "OC" = "_OC",
    "OR" = "_OR"
)
weight_options <- list(
    "default" = "", 
    "noposition" = "_noposition", 
    "freq" = "_freq", 
    "freq_noposition" = "_freq_noposition"
)

measures <- c("PG", "GP", "PG_freq", "G_freq", "P_freq")
statistics <- c("mean", "median", "max", "min", "sd")

batch_map_words <- function(spellings, pronunciations, grain_sizes, output_name) {
    dataset_names <- c()

    for (grain in names(grain_sizes)) {
        # Name of the mapped words dataset to be stored
        var_name <- paste0(output_name, grain_sizes[[grain]])

        # Call the relevant map function at the desired level
        data <- get(paste0("map", grain_sizes[[grain]]))(spellings, pronunciations, FALSE)

        # Save the dataset to the environment
        assign(var_name, data, envir = .GlobalEnv)

        # Add name of generated dataset to list
        dataset_names <- c(dataset_names, var_name)
    }

    # Return a list of names of generated datasets for easy removal from the environment later
    return(dataset_names)
}

generated_datasets <- batch_map_words(
  spellings = wordlist_v2_0$spelling,
  pronunciations = wordlist_v2_0$pronunciation,
  grain_sizes = grain_sizes,
  output_name = "mapped"
)

# Pull one mapped dataset back into the wordlist
wordlist_v2_0$PG <- get("mapped_PG")
wordlist_v2_0$ONC <- get("mapped_ONC")
wordlist_v2_0$OC <- get("mapped_OC")
wordlist_v2_0$OR <- get("mapped_OR")

# Write to CSV
write.csv(wordlist_v2_0, "pseudoword_measures.csv", row.names = FALSE)