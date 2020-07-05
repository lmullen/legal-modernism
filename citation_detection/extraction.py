import re
from test_text import *

versus_regex = r'\s[v]\.\s'
# Matches "v."

federal_reporter_regex = r'([0-9]{1,3}\s[A-Z].[0-3]d\s[0-9]{1,3})'
# Matches things like 545 F.3d 980

federal_supp_regex = r'([0-9]{1,3}\s[A-Z].\sSupp\.\s[0-4][a-e]\s[0-9]{1,3})'
# Matches things like 134 F. Supp. 2d 178

federal_short = r'([0-9]{1,3}\s[A-Z].[0-3]d\sat)'
# Matches things like 316 F.3d at 16

us_reports = r'([0-9]{1,3}\sU\.S\.\s[0-9]{1,3})'

catchall = r'([\d]{1,3}\s[a-zA-Z0-9\.]+\s[\d]{1,4})'


def combine_regex():
    # combined = "|".join([federal_reporter_regex, federal_supp_regex, federal_short, us_reports])
    combined = "|".join([federal_reporter_regex, catchall]) # Must join with some other regex to work. No idea why. 

    return combined


def extract(t):
    for x in t:
        if len(x) > 0:
            return x


test_match = re.compile(combine_regex())

raw_res = test_match.findall(test_text_3)
stripped_res = [extract(x) for x in raw_res]
print(stripped_res)


def process(t):
    regex = re.compile(combine_regex())

    raw_res = regex.findall(test_text_0)
    stripped_res = [extract(x) for x in raw_res]
    return stripped_res