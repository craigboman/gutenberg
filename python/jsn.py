import os, json, pickle, string
from nltk.tokenize import word_tokenize
from nltk.corpus import stopwords
from pathlib import Path


def pick(filename):
    os.chdir('/mnt/volume_nyc3_01/gutenberg/archive')
    file = open(filename, 'rt', errors='ignore') #probably not ideal to ignore encoding errors; technical debt later
        #file = open(filename, 'rt', encoding= utf8') for iso-8859 encoded files
    text = file.read()
    file.close()

    # split into words
    tokens = word_tokenize(text)

    # convert to lower case
    tokens = [w.lower() for w in tokens]

    # remove punctuation from each word
    table = str.maketrans('', '', string.punctuation)
    stripped = [w.translate(table) for w in tokens]
    # remove remaining tokens that are not alphabetic
    words = [word for word in stripped if word.isalpha()]
    # filter out stop words
    stop_words = set(stopwords.words('english'))
    words = [w for w in words if not w in stop_words]

    pth= '../json/'
    #failed attempt to split out base filename:  base = os.path.splitext(filename)[0]
    merge = os.path.join(pth, Path(filename).stem)
    with open(merge+'.json', 'w') as f:
        json.dump(words, f, ensure_ascii=False)
    f.close()
    return filename
    # jsn = merge+'.json'
    # os.rename(merge, jsn)

def loop():
    os.chdir('/mnt/volume_nyc3_01/gutenberg/archive')
    books = os.listdir()
    for i in books:
        pick(i)

loop()