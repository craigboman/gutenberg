import os, json, pickle, string
from nltk.tokenize import word_tokenize

from nltk.corpus import stopwords

filename = 'metamorphosis_clean.txt'

def pick(filename):
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

    path = '../json'
    with open(os.path.join(path,filename), 'w') as f:
        json.dump(words, f, ensure_ascii=False)
    f.close()

