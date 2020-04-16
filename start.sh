#!/bin/bash

service postgresq start
/home/foo/enhydris/venv/bin/python ./manage.py makemigrations --check
/home/foo/enhydris/venv/bin/python ./manage.py
/home/foo/enhydris/venv/bin/python ./manage.py runserver 0.0.0.0:8000

