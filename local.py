# flake8: NOQA
from . import *
DEBUG = True
ALLOWED_HOSTS=["*"]
DATABASES = {
    "default": {
        "ENGINE": "django.contrib.gis.db.backends.postgis",
        "NAME": "openmeteo",
        "USER": "openmeteo",
        "PASSWORD": "topsecret",
        "HOST": "localhost",
        "PORT": 5432,
    }
}
DATA_UPLOAD_MAX_NUMBER_FIELDS = 10000
ENHYDRIS_DISPLAY_COPYRIGHT_INFO = True
ENHYDRIS_USERS_CAN_ADD_CONTENT = True
ENHYDRIS_OPEN_CONTENT = True
LANGUAGE_CODE = "en"

