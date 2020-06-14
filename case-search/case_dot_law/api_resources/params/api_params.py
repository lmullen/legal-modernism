from furl import furl

class ApiParams:
    def __init__(self):
        self.test_attr = "blah"

    def append(self, url):
       _url = furl(url)
       _url.add(self.__dict__)

    #    attrs = self.__dict__ 
    #    for k, v in attrs.items():
    #     #    url += "&{0}={1}".format(k, v)


    #    print(url)
       return _url # Return for testing, not substantive, purposes.