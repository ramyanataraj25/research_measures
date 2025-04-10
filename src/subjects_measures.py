# import libraries that are necessary to write code
import csv
import pandas as pd
import subprocess

# read the subject file in and parse through removing "ɚɹ" the ɹ is it follows
# ɚ	or 3
def edit_pronunciations(ntr_task_file, concatenations):
    fixed_pronunciations = ''
    # reads in file and finds the specific row and fixes it
    with open(ntr_task_file, mode = 'r', encoding='utf-8') as in_file:
        reader = csv.reader(in_file)
        
        for row in reader:
            if len(row) > concatenations:
                fixed_pronunciations += ''.join(word.replace("ɚɹ","ɚ") 
                    for word in row[concatenations].split()) + "\n"
        
    # returns the word that is fixed
    return fixed_pronunciations.strip()

def process_subjects_to_csv(input_file, output_csv):
    try:
        # Read input CSV file
        df = pd.read_csv(input_file)
        df.columns = df.columns.str.strip()
        
        # Clean the Concatenate column first
        def clean_concatenation(text):
            if pd.isna(text) or text == 'noresp':
                return text
            return ''.join(word.replace("ɚɹ","ɚ") for word in str(text).split())
        
        # Apply cleaning to Concatenate column
        df['Concatenate'] = df['Concatenate'].apply(clean_concatenation)
        
        # Get all valid pronunciations at once
        valid_rows = df[~pd.isna(df['Concatenate']) & (df['Concatenate'] != 'noresp')]
        
        # Create pronunciations.csv with pseudowords
        pronunciations_df = pd.DataFrame({
            'X0': valid_rows['Pseudoword'],
            'toolkit_pron': valid_rows['Pseudoword']
        })
        pronunciations_df.to_csv('pronunciations.csv', index=False)
        
        # Run R script once for all pseudowords
        subprocess.run(['Rscript', 'src/get_pseudoword_measures.R'], check=True)
        
        # Read all measures at once
        measures_df = pd.read_csv('pseudoword_measures.csv')
        
        # Merge measures back into original dataframe
        result_df = pd.merge(
            df,
            measures_df,
            left_on='Pseudoword',
            right_on='spelling',
            how='left'
        )
        
        # Reorder columns
        columns_order = [
            'Paradigm order',
            'Pseudoword',
            'Concatenate'  # This will now have the cleaned concatenations
        ]
        # Add measure columns
        measure_columns = [col for col in measures_df.columns if col != 'spelling']
        columns_order.extend(measure_columns)
        
        # Save final result
        result_df = result_df[columns_order]
        result_df.to_csv(output_csv, index=False)
        print(f"Successfully created {output_csv}")
        return result_df
        
    except Exception as e:
        print(f"Error in process_subjects_to_csv: {e}")
        return None