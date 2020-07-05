import pytest

from citation_detection.extraction import process
from citation_detection.test_text import *

def test_basic():
    res = process(test_text_3)