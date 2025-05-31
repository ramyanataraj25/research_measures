# Research_Measures

A pipeline that processes subject-specific pseudowords and reproduces their associated Toolkit measures. 


## Setup

1. Install required Python packages

2. Ensure R is installed and the required R script is in the correct location.


## Usage

The main script `subject_files.py` processes pseudowords and reproduces their associated Toolkit measures for each inputted subject file, cleans the concatenated pronunciations, and outputs a csv containing all aggregated data. 

All final subject output files are stored in the /final_outputs directory

To run: python3 <path to the subejct_files.py file> <path to csv containing all subject names and their assoc. file paths>

Create a CSV file (e.g., `Subjects.csv`) with the following structure:
- `Subject Name`: Name of the subject (used for output filename)
- `File Path`: Full path to the subject's data file




