import os, json, pandas, string


def df(filename):
    path = '/mnt/volume_nyc3_01/gutenberg/json/'
    all = os.lisdir(path)
    part = all[:10]
    for i in part:
	file = open(path+i, 'rt', errors='ignore') #not ideal to ignore encoding errors
        df = json.load(file)
	file.close()

#continue trying to load pandas dataframes, but possibly going back to archive rather than json
#where one is ebook, second column is ebook subject headings, using filename as left-most index
