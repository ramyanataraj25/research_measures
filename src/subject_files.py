# import libraries that are necessary to write code
import argparse
import subprocess 
import pandas as pd
# import subjects_measures
import os
    
def create_new_subject_file(ntr_task_file, subject_file):
    
    # open the ntr_task_file file using a with statement
    with open(ntr_task_file, 'r', encoding='utf-8') as f:
        
    # open subject_file file with a with statement to write to it
        with open(subject_file, 'w', encoding='utf-8') as sub_f:
            # for sub_row in sub_f:

    # create a list that can store all the subject pronunciations
            for row in f:
                row = row.strip().split()
                if(len(row) < 2):
                    continue
                    # fix concatenations and edit the pronunciations
                new_pronunciations = subjects_measures.edit_pronunciations(
                ntr_task_file, 16)
                words_dict = {row[0], row[1], new_pronunciations}
    
    # write to the second file to contain all concatenated pronunciations
     # and words
                sub_f.write(str(words_dict) + '\n')
    
    return subject_file

#args: path to subject file, path to output csv file
def process_subjects_to_csv(input_file, output_csv):
    try:
        # Read input CSV file
        df = pd.read_csv(input_file)
        df.columns = df.columns.str.strip()
        
        # Clean the Concatenate column 
        df['Concatenate'] = df['Concatenate'].apply(
            lambda x: ''.join(word.replace("ɚɹ","ɚ") for word in str(x).split()) 
            if not pd.isna(x) and x != 'noresp' 
            else x
        )
        
        df = df.rename(columns={'Concatenate': 'participant_pronunciation'})
        
        # Get all valid rows (where participant_pronunciation isn't NA or 'noresp')
        valid_rows = df[~pd.isna(df['participant_pronunciation']) & (df['participant_pronunciation'] != 'noresp')]
        
        # Create pronunciations.csv with pseudowords, drop duplicates if any
        pronunciations_df = pd.DataFrame({
            'X0': valid_rows['Pseudoword'],
            'toolkit_pron': valid_rows['participant_pronunciation']
        }).drop_duplicates()
        pronunciations_df.to_csv('pronunciations.csv', index=False)
        
        # Run R script once for all pseudowords
        subprocess.run(['Rscript', '/Users/ramyanataraj/Documents/Research/research_measures/src/get_pseudoword_measures.R'], check=True)
        
        # Read result files
        measures_df = pd.read_csv('pseudoword_measures.csv')
        
        # Debug output
        print(f"Columns in pseudoword_measures.csv: {measures_df.columns.tolist()}")
        phoneme_cols = [col for col in measures_df.columns if '_phonemes' in col]
        grapheme_cols = [col for col in measures_df.columns if '_graphemes' in col]
        print(f"Phoneme columns: {phoneme_cols}")
        print(f"Grapheme columns: {grapheme_cols}")
        
        # Merge everything together
        result_df = pd.merge(
            df,
            measures_df,
            left_on='Pseudoword',
            right_on='spelling',
            how='left'
        ).drop_duplicates(subset=['Paradigm order', 'Pseudoword', 'participant_pronunciation'])
        
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
        
        # Reorder columns and save
        result_df = result_df[columns_order]
        result_df.to_csv(output_csv, index=False)
        print(f"Successfully created {output_csv}")
        return result_df
        
    except Exception as e:
        print(f"Error in process_subjects_to_csv: {e}")
        return None

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
        subject_name = row['Subject Name']
        
        # Clean and normalize the file path
        input_file = row['File Path']
        input_file = input_file.strip().strip('"').strip("'")  
        input_file = os.path.normpath(input_file)   
        input_file = os.path.abspath(input_file)     
        
        print(f"\nProcessing subject: {subject_name}")
        print(f"Using path: {input_file}")
        
        # Save output to final_outputs folder
        final_output = os.path.join(output_dir, f"final_{subject_name}.csv")
        
        # Process the subject's data
        processed_df = process_subjects_to_csv(input_file, final_output)
        
        if processed_df is not None:
            print(f"Successfully processed {subject_name}")
        else:
            print(f"Failed to process {subject_name}")

if __name__ == "__main__":
    main()

'''
    pipeline: iterate through all subject files, 
    chain through data cleaning functions, 
    pass into process_subjects_to_csv function, 
    and specify the output csv path
'''