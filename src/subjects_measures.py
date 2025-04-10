# import libraries that are necessary to write code
import csv

# read the subject file in and parse through removing "ɚɹ" the ɹ is it follows
# ɚ	or 3
corrected = []
def edit_pronunciations(ntr_task_file, output_file, concatenations):
    # reads in file and finds the specific row and fixes it
    with open(ntr_task_file, mode = 'r', encoding='utf-8') as in_file:
        
            reader = csv.reader(in_file)
        
            for row in reader:
                if len(row) > concatenations:
                    row[concatenations] = ' '.join(word.replace("ɚɹ","ɚ") 
                    for word in row[concatenations].split())
                corrected.append(row)
   
    # returns the file that is fixed
    with open(output_file, mode = 'w',newline='', encoding='utf-8') as out_file:        
            writer = csv.writer(out_file)
            writer.writerows(corrected)
    print(f"File processed and fixed: {out_file}")
        
    