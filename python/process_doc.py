#borrowed heavily from Jason Brownlee's word-level neural language tutorial

import string

# load doc into memory
def load_doc(filename):
	# open the file as read only
	file = open(filename, 'rU') #U is a universal newline char setting
	# read all text
	text = file.read()
	# close the file
	file.close()
	return text

# turn a doc into clean tokens
def clean_doc(doc):
	# replace '--' with a space ' '
	doc = doc.replace(' ', ' ')
	# split into tokens by white space
	tokens = doc.split()
	# remove punctuation from each token
	table = str.maketrans('', '', string.punctuation)
	tokens = [w.translate(table) for w in tokens]
	# remove remaining tokens that are not alphabetic
	tokens = [word for word in tokens if word.isalpha()]
	# make lower case
	tokens = [word.lower() for word in tokens]
	return tokens

# save tokens to file, one dialog per line
def save_doc(lines, filename):
        data = '\n'.join(lines)
        file = open(filename, 'w')
        file.write(data)
        file.close()


#one line combining load, clean, save_doc; outputs sequences 
def loadClean(dirt):
	doc = load_doc(dirt)
	tokens = clean_doc(doc)
	
	# organize into sequences of tokens
	length = 50 + 1
	sequences = list()
	for i in range(length, len(tokens)):
		# select sequence of tokens
		seq = tokens[i-length:i]
		# convert into a line
		line = ' '.join(seq)
		# store
		sequences.append(line)

	out_filename = 'republic_sequences.txt'
	save_doc(sequences, out_filename)
