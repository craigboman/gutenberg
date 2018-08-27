import re, gensim, spacy, pyLDAvis, pyLDAvis.gensim, logging, warnings
import numpy as py
import pandas as pd
from pprint import pprint

import gensim.corpora as corpora
from gensim.utils import simple_preprocess
from gensim.models import CoherenceModel

import matplotlib.pyplot as plt #requires apt-get install python3-tk
#%matplotlib inline only relevant for jupyter notebook

logging.basicConfig(format='%(asctime)s : %(levelname)s : %(message)s', level=logging.ERROR)

warnings.filterwarnings("ignore", category=DeprecationWarning)
