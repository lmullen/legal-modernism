import requests
from config import API_KEY # pylint: disable=E0611

api_root = 'https://api.case.law/v1/'

def _generate_request_headers():
    return {'Token': API_KEY} 

class ApiRequester(): 
    def __init__(self, thing): # The thing we are requesting. Case.law only has cases, as it so happens.
        self.url = api_root + thing +"/"
    
    def get(self, url): 
        print(url)