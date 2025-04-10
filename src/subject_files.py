# import libraries that are necessary to write code
import argparse
import subprocess 
import pandas as pd
import subjects_measures
import os

def create_new_subject_file(input_file, output_file):
     print(f"Attempting to open file: {input_file}")
     try:
         # Read the input file using pandas instead of direct file reading
         df = pd.read_csv(input_file)
    # Write the processed data to the output file
         df.to_csv(output_file, index=False)
         return output_file
         
     except FileNotFoundError:
         print(f"Error: Could not find the file at path: {input_file}")
         print(f"Current working directory: {os.getcwd()}")
         raise
     except Exception as e:
         print(f"Error while processing file: {str(e)}")
         raise
# def create_new_subject_file(ntr_task_file, subject_file):
#     try: 
#      # open the ntr_task_file file using a with statement
#         with open(ntr_task_file, 'r', encoding='utf-8') as f:
    
#         # open subject_file file with a with statement to write to it
#             with open(subject_file, 'w', encoding='utf-8') as sub_f:
#                 # for sub_row in sub_f:
    
#                 # create a list that can store all the subject pronunciations
#                 i =0
#                 for row in f:
                    
#                     row = row.strip().split()
#                     if(len(row) < 2):
#                         continue
#                     # fix concatenations and edit the pronunciations
#                     new_pronunciations = subjects_measures.edit_pronunciations(
#                     ntr_task_file, 16)
#                     words_dict = {row[i], row[i+1], new_pronunciations}
#                     i = i + 1
        
#                     # write to the second file to contain all concatenated pronunciations
#                     # and words
#                     sub_f.write(str(words_dict) + '\n')
#                     print(subject_file)
#                     return subject_file
    # except FileNotFoundError:
    #     print(f"Error: Could not find the file at path: {ntr_task_file}")
    #     print(f"Current working directory: {os.getcwd()}")
    #     raise
    # except Exception as e:
    #     print(f"Error while processing file: {str(e)}")
    #     raise
 
     


#args: path to subject file, path to output csv file
def process_subjects_to_csv(input_file, output_csv):
    try:
        # Read input CSV file
        df = pd.read_csv(input_file)
        df.columns = df.columns.str.strip()
        
        # Get all valid rows (where Concatenate isn't NA or 'noresp')
        valid_rows = df[~pd.isna(df['Concatenate']) & (df['Concatenate'] != 'noresp')]
        
        # Create pronunciations.csv with pseudowords
        pronunciations_df = pd.DataFrame({
            'X0': valid_rows['Pseudoword'],
            'toolkit_pron': valid_rows['Pseudoword']
        })
        pronunciations_df.to_csv('pronunciations.csv', index=False)
        
        # Run R script once for all pseudowords
        subprocess.run(['Rscript', '/Users/christine/research_measures/src/get_pseudoword_measures.R'], check=True)
        
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
        
        # Reorder columns to ensure desired order
        # Keep original columns first, then add measures
        columns_order = [
            'Paradigm order',
            'Pseudoword',
            'Concatenate'
        ]
        # Add all the measure columns (excluding 'spelling' which we used for merging)
        measure_columns = [col for col in measures_df.columns if col != 'spelling']
        columns_order.extend(measure_columns)
        
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
    
    # Read the subjects CSV file
    subjects_df = pd.read_csv(args.subjects_csv)
    subjects_df.columns = subjects_df.columns.str.strip()
    
    for index, row in subjects_df.iterrows():
        subject_name = row['Subject Name']
        input_file = row['File Path']
        
        print(f"\nProcessing subject: {subject_name}")
        # print(f"Input file path: {input_file}")
        
        # # Generate output filenames based on subject name in current directory
        # subject_generated = f"{subject_name}_generated.csv"
        final_output = f"final_{subject_name}.csv"
        
        # # Generate subject file
        # new_subject_file = create_new_subject_file(input_file, subject_generated)
        
        print(f"Completed processing for {subject_name}\n")
        processed_df = process_subjects_to_csv(input_file, final_output)
        print(f"Completed processing for {subject_name}\n")

        # # Process subject data and create final output
        # temp = process_subjects_to_csv(new_subject_file, final_output)
        # print(temp)
        
        

if __name__ == "__main__":
    main()

''' ran code as: python3 /Users/ramyanataraj/Documents/Research/research_measures
/src/subject_files.py "/Users/ramyanataraj/Documents/Research
/research_measures/subject_test_files/Final 0057_task-pw_run-1.xlsx - 
 Hana.csv" "/Users/ramyanataraj/Documents/Research
/research_measures/subject_test_files/Hana_generated.csv" "/Users/ramyanataraj/Documents/Research/research_measures
/subject_test_files/final_Hana.csv" 
'''

'''
    pipeline: iterate through all subject files, 
    chain through data cleaning functions, 
    pass into process_subjects_to_csv function, 
    and specify the output csv path
'''