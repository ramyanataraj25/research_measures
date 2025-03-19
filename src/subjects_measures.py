# import libraries that are necessary to write code
import csv

# read the subject file in and parse through removing "ɚɹ" the ɹ is it follows
# ɚ	or 3
def edit_pronunciations(ntr_task_file, concatenations):
    fixed_pronunciations = ''
    with open(ntr_task_file, mode = 'r', encoding='utf-8') as in_file:
        reader = csv.reader(in_file)
        
        for row in reader:
            if len(row) > concatenations:
                fixed_pronunciations += ''.join(word.replace("ɚɹ","ɚ") 
                    for word in row[concatenations].split()) + "\n"
        
    return fixed_pronunciations.strip()
        

# take file created from previous file (so subject_file) and apply conversion 
# code to convert IPA to toolkit conventions (from Caleb)