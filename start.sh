#!/bin/bash

service postgresql start
/home/foo/enhydris/venv/bin/python ./manage.py makemigrations --check
/home/foo/enhydris/venv/bin/python ./manage.py migrate
/home/foo/enhydris/venv/bin/python ./manage.py runserver 0.0.0.0:8000

