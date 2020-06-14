from furl import furl

def _keep(v):
    return v not in ("", False)

class ApiParams:
    # def __init__(self):
        # self.test_attr = "blah"

    def append(self, url):
       _url = furl(url)

       all_attrs = self.__dict__
       filtered = {k: v for k, v in all_attrs.items() if _keep(v)}

       _url.add(filtered)

       return _url 
    