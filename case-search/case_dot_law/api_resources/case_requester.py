from case_dot_law.api_resources.api_requester import ApiRequester

class CaseRequester(ApiRequester):
    def __init__(self):
        super().__init__("cases")
    
    def get(self):
        # print(self.url)
        super().get(self.url)
