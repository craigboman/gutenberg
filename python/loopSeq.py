import os, jsn
from jsn import pick

def loop():
    os.chdir('/mnt/volume_nyc3_01/gutenberg/archive')
    books = os.listdir()
    for i in books:
        pick(i)

loop()