import requests, bs4, pickle, zipfile, io, os
from bs4 import BeautifulSoup
#beautiful soup only used for parsing html

def unzp(zip_file_url):
    r = requests.get(zip_file_url)
    z = zipfile.ZipFile(io.BytesIO(r.content))
    z.extractall()
    return z


def read():
    books = 
	['archive/31279-8.txt',
	'archive/43999.txt',
	'archive/31256-8.txt',
	'archive/41256-8.txt',
	'archive/37840-8.txt',
	'archive/37825-8.txt',
	'archive/37766-8.txt',
	'archive/31125-8.txt']

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
