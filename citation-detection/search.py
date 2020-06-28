import re
from test_text import *

versus_regex = r'\s[v]\.\s'
# Matches "v." 

federal_reporter_regex = r'([0-9]{1,3}\s[A-Z].[0-3]d\s[0-9]{1,3})'
# Matches things like 545 F.3d 980

federal_supp_regex = r'[0-9]{1,3}\s[A-Z].\sSupp\.\s[0-4][a-e]\s[0-9]{1,3}'
# Matches things like 134 F. Supp. 2d 178

# def combine_regex():


test_match = re.compile(federal_reporter_regex)

# print(test_text_0)
res = test_match.findall(simple_reporter_test)
print(res)