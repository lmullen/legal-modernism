from requests import get
from case_dot_law.cases import Cases

# h = case_dot_law.generate_request_headers() 
# print(h)

c = Cases()
c.get("54 F.3d 241")

