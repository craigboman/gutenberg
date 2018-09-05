import os, json, string
import pandas as pd
from pathlib import Path

def df(filename):
    path = '/mnt/volume_nyc3_01/gutenberg/archive/'
    mp = '/mnt/volume_nyc3_01/gutenberg/metadata/'    

    all = os.lisdir(path)
    part = all[:10]
    i = part[1] #used later for stem metadata lookup
    file = open(path+i, 'rt', errors='ignore') #not ideal to ignore encoding errors
    df = file.read()
    file.close()

    #lookup stem metadata
    stm = Path(i).stem
    #should be conditional string split 
    i = i.split('-')[0]

    #use python xml decode to read .rdf files    

#continue trying to load pandas dataframes, but possibly going back to archive rather than json
#where one is ebook, second column is ebook subject headings, using filename as left-most index
