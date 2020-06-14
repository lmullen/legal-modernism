import case_dot_law.api_requester as api_requester # pylint: disable=E0611

class Cases():
    def __init__(self):
        self.requestor = api_requester.ApiRequester("cases")

    def get(self, guid, full=False):
        self.requestor.get(guid) 