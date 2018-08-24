import os
from jsn import pick

def loop():
    os.chdir('/mnt/volume_nyc3_01/gutenberg/books')
    books = os.listdir()
    for i in books:
        pick(i)