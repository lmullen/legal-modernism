# case-search

##Basic Installation

Windows
--------

1. Install Python 2.7.9
2. Add Python to your System Path by navigating to Control Panel > System. Click on "Advanced System Settings" (on the left). 
    Click on "Environment Variables" (bottom). Under "System variables" find "Path" and edit it. Add `path\to\your\python\installation` and `path\to\your\python\installation\Scripts` to your Path. Note that entries to the Path are delimited by ";". 
    If you use Git Bash you should add your Python installation to the path there as well by adding the following lines to your .bashrc : `PATH=$PATH:/c/Python27/` and `PATH=$PATH:/c/Python27/Scripts`.
3. Install [virtualenv](https://github.com/pypa/virtualenv) by running `pip install virtualenv` via cmd.
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