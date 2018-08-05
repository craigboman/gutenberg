import requests, bs4, pickle, zipfile, io, os
from bs4 import BeautifulSoup
#beautiful soup only used for parsing html

def unzp(zip_file_url):
    r = requests.get(zip_file_url)
    z = zipfile.ZipFile(io.BytesIO(r.content))
    z.extractall()
    return z


def read():
	books = ['books/Homer.txt', 'books/Pessoa.txt', 'books/Miller.txt', 'books/Anonymous.txt', 'books/Steward.txt', 'books/Hays.txt', 'books/Burke.txt', 'books/Cambridge.txt', 'books/Unknown.txt', 'books/Harper.txt']




    authors = ['Homer',
        'Pessoa',
        'Miller',
        'Anonymous',
        'Steward',
        'Hays',
        'Burke',
        'Cambridge',
        'Unknown',
        'Harper']

    data = open("archive/24269-8.txt", "rb")
    page = data.read()
    data.close 
