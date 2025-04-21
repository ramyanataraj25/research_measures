# setwd("Replace this string with the path to the full-pipeline directory of this repo and uncomment")
# The Toolkit only needs to be loaded once
load("/Users/christine/NTR/Toolkit/Toolkit_v2.0.RData")

# By default, this script generates the all_words, all_tables, and scored_words family of datasets,
# and write them to an output csv.
# present in the precomputed Toolkit data.
# To adapt it to your own lists, simply changing the variables here and running the script will suffice.
# All functions within are taken from scripts/all-measures/extract_all_measures.R and 
# scripts/batch-mapping/batch_mapping_pipeline.R

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
batch_make_tables <- function(mapped_words_name, grain_sizes, weight_options, weight_data, output_name) {
    dataset_names <- c()

    for (grain in names(grain_sizes)) {
        mapped_words <- get(paste0(mapped_words_name, grain_sizes[[grain]]))
        for (weight in names(weight_options)) {
            var_name <- paste0(output_name, grain_sizes[[grain]], weight_options[[weight]])
            data <- c() # init empty

            if (weight == "default") {
                data <- make_tables(mapped_words)
            } else if (weight == "noposition") {
                data <- make_tables(mapped_words, positional = FALSE)
            } else if (weight == "freq") {
                data <- make_tables(mapped_words, weight = weight_data)
            } else if (weight == "freq_noposition") {
                data <- make_tables(mapped_words, weight = weight_data, positional = FALSE)
            }
            assign(var_name, data, envir = .GlobalEnv)

            dataset_names <- c(dataset_names, var_name)
        }
    }

    return(dataset_names)
}
batch_map_values <- function(spellings, pronunciations, table_name, grain_sizes, weight_options, output_name) {
    dataset_names <- c()
    
    for (grain in names(grain_sizes)) {
        for (weight in names(weight_options)) {
            data_table <- get(paste0(table_name, grain_sizes[[grain]], weight_options[[weight]]))
            var_name <- paste0(output_name, grain_sizes[[grain]], weight_options[[weight]])

            data <- map_value(spellings, pronunciations, grain, data_table)

            assign(var_name, data, envir = .GlobalEnv)

            dataset_names <- c(dataset_names, var_name)
        }
    }

    return(dataset_names)
}

extract_summary <- function(root, grain, weight, measure) {
  # Create the appropriate dataset name
  dataset <- paste0(root, grain, weight)

  summary <- summarize_words(get(dataset), measure)
  colnames(summary)[1] <- "spelling"
  colnames(summary)[2] <- "pronunciation"

  return(summary)
}
filter_columns <- function(df, statistics) {
  col_names <- colnames(df)

  keep_cols <- sapply(col_names, function(col) {
    if (col %in% c("spelling", "pronunciation")) {
      return(TRUE) # Always keep these columns
    }
    if (grepl("\\.", col)) {
      suffix <- sub(".*\\.", "", col) # Extract part after last period
      return(suffix %in% statistics) # Exclude columns with unwanted statistics
    }
    return(TRUE) # Keep columns without a period
  })

  return(df[, keep_cols, drop = FALSE])
}
get_measures <- function(mapped_values_name, grain_sizes, weight_options, measures, statistics) {
  results_list <- list()

  i <- 1
  for (measure in measures) {
    for (grain in names(grain_sizes)) {
      for (weight in names(weight_options)) {
        print(paste0("doing iter ", i, " for dataset ", mapped_values_name, grain_sizes[[grain]], weight_options[[weight]], " and measure ", measure))

        summary_result <- extract_summary(mapped_values_name, grain_sizes[[grain]], weight_options[[weight]], measure)

        if (length(results_list) == 0) {
          # Include spelling and pronunciation columns only in the first iteration
          results_list[[paste0(grain, "_", weight, "_", measure)]] <- summary_result
        } else {
          # Subsequent summaries exclude spelling and pronunciation columns
          results_list[[paste0(grain, "_", weight, "_", measure)]] <- summary_result[, -c(1, 2)]
        }
        i <- i + 1
      }
    }
  }
  
  # Combine all summaries into a single data frame
  combined_results <- do.call(cbind, results_list)
  colnames(combined_results)[1:2] <- c("spelling", "pronunciation")
  
  combined_results <- filter_columns(combined_results, statistics)

  return(combined_results)
}

batch_map_words(spellings, pronunciations, grain_sizes, mapped_words_output_name)
batch_make_tables(mapped_words_output_name, grain_sizes, weight_options, freq_weights, made_tables_output_name)
batch_map_values(spellings, pronunciations, made_tables_output_name, grain_sizes, weight_options, mapped_values_output_name)

all_measures <- get_measures(mapped_values_output_name, grain_sizes, weight_options, measures, statistics)
write.csv(all_measures, "all_measures.csv")






