# import libraries that are necessary to write code
import argparse
import subprocess 
import pandas as pd
import os


#args: path to subject file, path to output csv file
def process_subjects_to_csv(input_file, output_dir):
    try:
        # Read input CSV file
        df = pd.read_csv(input_file)
        df.columns = df.columns.str.strip()
        
        # Clean the Concatenate column using the same logic as edit_pronunciations
        df['Concatenate'] = df['Concatenate'].apply(
            lambda x: ''.join(word.replace("ɚɹ","ɚ") for word in str(x).split()) 
            if not pd.isna(x) and x != 'noresp' 
            else x
        )
        
        # Rename the Concatenate column to participant_pronunciation
        df = df.rename(columns={'Concatenate': 'participant_pronunciation'})
        
        # Get all valid rows (where participant_pronunciation isn't NA or 'noresp')
        valid_rows = df[~pd.isna(df['participant_pronunciation']) & (df['participant_pronunciation'] != 'noresp')]
        
        # Get the most common pronunciation for each pseudoword
        pseudoword_pronunciations = {}
        for pseudoword in valid_rows['Pseudoword'].unique():
            # Get all valid pronunciations for this pseudoword
            pronunciations = valid_rows[valid_rows['Pseudoword'] == pseudoword]['participant_pronunciation'].tolist()
            
            # Count occurrences of each pronunciation
            pronunciation_counts = {}
            for pron in pronunciations:
                if pron in pronunciation_counts:
                    pronunciation_counts[pron] += 1
                else:
                    pronunciation_counts[pron] = 1
            
            # Find the most common pronunciation
            most_common_pron = max(pronunciation_counts, key=pronunciation_counts.get)
            
            # Check if there's a tie (all pronunciations occur the same number of times)
            max_count = pronunciation_counts[most_common_pron]
            tie = all(count == max_count for count in pronunciation_counts.values())
            
            if tie and len(pronunciation_counts) > 1:
                # If there's a tie, use the first pronunciation that appears in the data
                most_common_pron = pronunciations[0]
                print(f"Tie for pseudoword '{pseudoword}' - using first pronunciation: '{most_common_pron}'")
            else:
                print(f"For pseudoword '{pseudoword}', using most common pronunciation: '{most_common_pron}' (occurs {max_count}/{len(pronunciations)} times)")
            
            pseudoword_pronunciations[pseudoword] = most_common_pron
        
        # Create pronunciations.csv with pseudowords and their most common pronunciations
        pronunciations_df = pd.DataFrame({
            'X0': list(pseudoword_pronunciations.keys()),
            'toolkit_pron': list(pseudoword_pronunciations.values())
        })
        pronunciations_df.to_csv('src/pronunciations.csv', index=False)
        
        # Run R script once for all pseudowords
        subprocess.run(['Rscript', '/Users/christine/research_measures/src/get_pseudoword_measures.R'], check=True)
        
        # Read result files
        measures_df = pd.read_csv('src/pseudoword_measures.csv')
        
        # Debug output
        phoneme_cols = [col for col in measures_df.columns if '_phonemes' in col]
        grapheme_cols = [col for col in measures_df.columns if '_graphemes' in col]

        
        # Create a subset of the original dataframe with unique pseudowords
        # This preserves the order and other columns from the original data
        unique_pseudowords = df.drop_duplicates(subset=['Paradigm order', 'Pseudoword'])
        
        # Merge with the measures dataframe
        result_df = pd.merge(
            unique_pseudowords,
            measures_df,
            left_on='Pseudoword',
            right_on='spelling',
            how='left'
        )
        
        # Add the most common pronunciation for each pseudoword
        result_df['participant_pronunciation'] = result_df['Pseudoword'].map(pseudoword_pronunciations)
        
        # Reorder columns
        columns_order = [
            'Paradigm order',
            'Pseudoword',
            'participant_pronunciation',
        ]
        
        # Add phoneme and grapheme columns
        phoneme_grapheme_cols = phoneme_cols + grapheme_cols
        columns_order.extend(phoneme_grapheme_cols)
        
        # Add the measure columns
        measure_columns = [col for col in measures_df.columns 
                         if col not in ['spelling', 'pronunciation'] + phoneme_grapheme_cols]
        columns_order.extend(measure_columns)
        
        # Make sure all required columns exist
        columns_order = [col for col in columns_order if col in result_df.columns]
        
        # Reorder columns
        result_df = result_df[columns_order]
        
        # Determine the next available NTR number
        subject_number = 1
        while True:
            # Check if file with this number already exists
            output_filename = f"ntr{subject_number:04d}-toolkit-reading_measures.csv"
            output_path = os.path.join(output_dir, output_filename)
            
            if not os.path.exists(output_path):
                break
            
            subject_number += 1
        
        # Save with the unique NTR number
        result_df.to_csv(output_path, index=False)
        print(f"Successfully created {output_path}")
        return result_df, subject_number
        
    except Exception as e:
        print(f"Error in process_subjects_to_csv: {e}")
        return None, None

def main():
    parser = argparse.ArgumentParser(
        description="Process subject files listed in a CSV and create measures.")
    parser.add_argument("subjects_csv", help="Path to the CSV containing subject file paths")
    
    args = parser.parse_args()
    
    # Get the root directory dynamically (where src folder is located)
    current_dir = os.path.dirname(os.path.abspath(__file__))  
    root_dir = os.path.dirname(current_dir)  
    
    # Create final_outputs directory in root if it doesn't exist
    output_dir = os.path.join(root_dir, "final_outputs")
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    
    # Read the subjects CSV file
    subjects_df = pd.read_csv(args.subjects_csv)
    subjects_df.columns = subjects_df.columns.str.strip()
    
    for index, row in subjects_df.iterrows():
        subject = row['Subject']
        
        # Clean and normalize the file path
        input_file = row['File Path']
        input_file = input_file.strip().strip('"').strip("'")  
        input_file = os.path.normpath(input_file)   
        input_file = os.path.abspath(input_file)     
        
        print(f"\nProcessing subject: {subject}")
        
        # Save output to final_outputs folder
        final_output = os.path.join(output_dir, f"{subject}-toolkit-reading_measures.csv")
        
        # Process the subject's data
        processed_df = process_subjects_to_csv(input_file, final_output)
        
        if processed_df is not None:
            print(f"Successfully processed {subject}")
        else:
            print(f"Failed to process {subject}")

if __name__ == "__main__":
    main()

