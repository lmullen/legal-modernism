class ApiParams:
    def __init__(self):
        self.full = False
        self.term = "blah"
    
    def append(self, url):
       attrs = self.__dict__ 
       for k, v in attrs.items():
           url += "&{0}={1}".format(k, v)

    #    print(url)
       return url # Return for testing, not substantive, purposes.