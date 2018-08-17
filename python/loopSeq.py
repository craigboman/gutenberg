import os
from process_doc import load_doc, clean_doc, save_doc, loadClean


def loopSeq:
    #function to loop through PG ebooks and output sequence.txt files 
    dir = '/home/science/gutenberg/archive'    
    files = os.listdir()

    for x in files: 
	print x
	load_doc(x) #running into char encoding errors 37815-8.txt; use iconv to convert encoding
		
