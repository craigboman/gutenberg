#inspired by https://www.machinelearningplus.com/nlp/topic-modeling-gensim-python/

import re, gensim, spacy, pyLDAvis, pyLDAvis.gensim, logging, warnings, os, json, io
import numpy as py
import pandas as pd
from pprint import pprint

import gensim.corpora as corpora
from gensim.utils import simple_preprocess
from gensim.models import CoherenceModel

import matplotlib.pyplot as plt #requires apt-get install python3-tk
#%matplotlib inline only relevant for jupyter notebook

from io import StringIO

logging.basicConfig(format='%(asctime)s : %(levelname)s : %(message)s', level=logging.ERROR)

warnings.filterwarnings("ignore", category=DeprecationWarning)

#since we've already serialized all of our ebooks into json we're skipping some steps here
#later we'll throw this into a loop

#we'll use all later, in a loop
all  = os.listdir('json') 
title = all[0]
file = open('json/'+title, 'rU', errors='ignore')
text = file.read() #data words is naming convention used later bigram trigram
file.close()

#almost forgot to do json decoding
data_words = json.loads(text)

# Build the bigram and trigram models
bigram = gensim.models.Phrases(data_words, min_count=5, threshold=100) # higher threshold fewer phrases.
trigram = gensim.models.Phrases(bigram[data_words], threshold=100)

# Faster way to get a sentence clubbed as a trigram/bigram
bigram_mod = gensim.models.phrases.Phraser(bigram)
trigram_mod = gensim.models.phrases.Phraser(trigram)

# See trigram example
print(trigram_mod[bigram_mod[data_words[0]]])
