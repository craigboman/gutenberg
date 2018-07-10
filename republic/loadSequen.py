from process_doc import load_doc
from keras.preprocessing.text import Tokenizer


def loadSeqEncode(filename):
	##loads clean sequences and tokenizes

	doc = load_doc(filename)
	lines - doc.split('\n')
	
	#will not run without import tokenizer from keras
	tokenizer = Tokenizer()
	tokenizer.fit_on_texts(lines)
	sequences = tokenizer.texts_to_sequences(lines)
