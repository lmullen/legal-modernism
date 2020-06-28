import re
from test_text import *

versus_regex = r'\s[v]\.\s'
# Matches "v." 

federal_reporter_regex = r'([0-9]{1,3}\s[A-Z].[0-3]d\s[0-9]{1,3})'
# Matches things like 545 F.3d 980

federal_supp_regex = r'([0-9]{1,3}\s[A-Z].\sSupp\.\s[0-4][a-e]\s[0-9]{1,3})'
# Matches things like 134 F. Supp. 2d 178

def combine_regex():
    combined = "|".join([federal_reporter_regex, federal_supp_regex])
    return combined

def extract(t):
    for x in t:
        if len(x) > 0:
            return x

test_match = re.compile(combine_regex())

# print(test_text_0)
raw_res = test_match.findall(combined_reporter_supp)
stripped_res = [extract(x) for x in raw_res] 
print(stripped_res)