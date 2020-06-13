from requests import get
import cases.sources.case_dot_law.utils as case_dot_law

h = case_dot_law.generate_request_headers() 
print(h)

