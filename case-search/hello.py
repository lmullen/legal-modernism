from requests import get

r = get('https://requests.readthedocs.io/en/master/')
print(r.status_code)