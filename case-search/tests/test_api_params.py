import pytest

from case_dot_law.api_resources.params.api_params import ApiParams

def test_append_question_mark():
    # Kind of unncessary since, after stubbing out the test, I realized I should find a library to do all the URL stuff, and found furl.
    test_url = "google.com"
    test_params = ApiParams()

    test_params.attr1 = "blah"

    res = test_params.append(test_url).url
    print(res)

    assert "?" in res 

# def test_disinclude_empty_params():
