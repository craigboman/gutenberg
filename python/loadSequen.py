from process_doc import load_doc
from keras.preprocessing.text import Tokenizer
from numpy import array
from keras.utils import to_categorical


def loadSeqEncode(filename): 
	##loads clean sequences and tokenizes; filename = republic_sequences.txt

	doc = load_doc(filename) #load republic_sequences.txt
	lines = doc.split('\n')
	
	#will not run without import tokenizer from keras
	tokenizer = Tokenizer()
	tokenizer.fit_on_texts(lines)
	sequences = tokenizer.texts_to_sequences(lines)
	#converts every word into a numerical array, line by line

	vocab_size = len(tokenizer.word_index) + 1

	#
	# separate into input and output
	sequences = array(sequences)
	X, y = sequences[:,:-1], sequences[:,-1]
	#currently this following command fails with a memoryError
	y = to_categorical(y, num_classes=vocab_size)
	seq_length = X.shape[1]






