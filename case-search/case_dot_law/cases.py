from case_dot_law.api_resources.case_requester import CaseRequester # pylint: disable=E0611

class Cases():
    def __init__(self):
        self.requestor = CaseRequester() 

    def get(self, guid, full=False):
        self.requestor.get() 
    
