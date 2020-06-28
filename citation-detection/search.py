import re
from test_text import *

versus_regex = r'\s[v]\.\s'
federal_reporter_regex = r'[0-9]{1,3}\s[A-Z].\s'
federal_supp_regex = r'[0-9]{1,3}\s[A-Z].\sSupp\.\s[0-4][a-e]\s[0-9]{1,3}'

test_match = re.compile(federal_supp_regex)

# print(test_text_0)
res = test_match.findall(multi_supp_test)
print(res)