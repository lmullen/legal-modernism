# case-search

##Basic Installation

Windows
--------

1. Install the latest version of Python (note that this project was originally written in Python 3.8.3) and [Visual Studio Code](https://code.visualstudio.com/docs/python/python-tutorial). Using Visual Studio Code obscures some of the Python messiness and helps you get started faster.
2. The above VS Code instructions explain how to get started using virtual environments as well.
3. Anyways, one thing to note is that for some reason all commands run through the VS Code integrated terminal for some reason use `py -m` instead of `python`, and require preface with `py -m` where they otherwise wouldn't on a Linux system. E.g. `py -m pip install <some package>` instead of `pip install <some package>`, `py hello.py` instead of `python hello.py`.
4. Follow the virtualenv setup instructions to create a virtualenv in the root of your clone of this repository. For example purposes, let's say you create a virtualenv named "env".
5. Activate the virtualenv by running `source env/Scripts/activate`.  
6. Run `pip install -r requirements.txt` to install the dependencies.
7. Run `python setup.py install` to install the project.


UNIX Based Systems
---------------------
1. Install [pipenv](https://pipenv.pypa.io/en/latest/install/#installing-pipenv). 
2. Follow the virtualenv setup instructions to create a virtualenv in the root of your clone of this repository. For example purposes, let's say you create a virtualenv named "env".
3. Activate the virtualenv by running `./env/bin/activate`
4. Run `pip install -r requirements.txt` to install the dependencies.
5. Run `python setup.py install` to install the project.

##Running Tests

1. Run `py.test tests`