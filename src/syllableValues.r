cat("Starting syllableValues.r...\n")
flush.console()

setwd("/Users/ramyanataraj/Documents/Research/toolkit-2.0-main")
load("/Users/ramyanataraj/Documents/Research/toolkit-2.0-main/Toolkit_v2.0.RData")
source("/Users/ramyanataraj/Documents/Research/research_measures/src/Transcription_Converter.R")
source("/Users/ramyanataraj/Documents/Research/toolkit-2.0-main/processing/PROCESSING_SCRIPTS.R")

cat("Processing...\n")
flush.console()

pseudowords_measures <- read.csv("pseudoword_measures.csv")

# Read and convert pronunciations
pronunciations <- pseudowords_measures$pronunciation
spellings <- pseudowords_measures$spelling

mapped_words_output_name <- "all_words"
made_tables_output_name <- "all_tables"
mapped_values_output_name <- "scored_words"

cat("vars made...\n")
flush.console()

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

cat("function running...\n")
flush.console()

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

cat("dataset...\n")
flush.console()

generated_datasets <- batch_map_words(spellings, pronunciations, 
    grain_sizes, "map")

# Pull one mapped dataset back into the wordlist
wordlist_v2_0$PG <- get(generated_datasets[["map_PG"]])
wordlist_v2_0$ONC <- get(generated_datasets[["map_ONC"]])
wordlist_v2_0$OC <- get(generated_datasets[["map_OC"]])
wordlist_v2_0$OR <- get(generated_datasets[["map_OR"]])

cat("csv creating...\n")
flush.console()

# Write to CSV
write.csv(wordlist_v2_0, "pseudoword_measures.csv", row.names = FALSE)

cat(wordlist_v2_0.head())
flush.console()