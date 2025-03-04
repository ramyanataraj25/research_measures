import subjects_measures

def create_new_subject_file(ntr_task_file, subject_file):
    
    # open the ntr_task_file file using a with statement
    with open(ntr_task_file, 'r', encoding='utf-8') as f:
        
    # open subject_file file with a with statement to write to it
        with open(subject_file, 'w', encoding='utf-8') as sub_f:
            for sub_row in sub_f:

    # create a list that can store all the subject pronunciations
                for row in f:
                    # fix concatenations and edit the pronunciations
                    new_pronunciations = subjects_measures.edit_pronunciations(
                        row[16])
                    words_dict = {row[0], row[1], new_pronunciations}
    
    # write to the second file to contain all concatenated pronunciations
     # and words
                    sub_row.write(words_dict)
    
    return subject_file
