import requests, bs4, pickle, zipfile, io
from bs4 import BeautifulSoup

def unzp(zip_file_url):
    r = requests.get(zip_file_url)
    z = zipfile.ZipFile(io.BytesIO(r.content))
    z.extractall()
    return z
