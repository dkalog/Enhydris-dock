# use of an ubuntu base for simplicity and transparency
#FROM ubuntu:18.04
FROM python:3.7-slim-buster
# set environment variables
ADD VERSION .
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# getting postgres
RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y wget gnupg2 

#RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -

# Add PostgreSQL's repository. It contains the most recent stable release
#     of PostgreSQL, ``11``.
#RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ buster-pgdg main" > /etc/apt/sources.list.d/pgdg.list

# Install software-properties-common and PostgreSQL 11
#  and some other packages for ftp
RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y \
  git virtualenv python3-virtualenv python3-pip python3-psycopg2 \
  python3-dev libjpeg-dev libfreetype6-dev  python3-pil \
  software-properties-common \
  postgresql-postgis \
  postgresql-postgis-scripts \
  aptitude  \
  unzip \
  openssh-client \
  openssh-server \
  sshpass \
  && aptitude update \
  && aptitude install -y nano axel wput screen p7zip-full osmium-tool \
  vnstat gdal-bin libgdal-dev \
  rm -rf /var/lib/apt/lists/*


WORKDIR /home/foo
RUN ["git", "clone", "https://github.com/openmeteo/enhydris.git"]
WORKDIR /home/foo/enhydris
CMD git checkout master


RUN virtualenv --python=/usr/bin/python3 --system-site-packages /home/foo/enhydris/venv
RUN /home/foo/enhydris/venv/bin/pip install psycopg2
RUN /home/foo/enhydris/venv/bin/pip install gdal==2.4.0
RUN /home/foo/enhydris/venv/bin/pip install -r requirements.txt
RUN /home/foo/enhydris/venv/bin/pip install -r requirements-dev.txt
RUN /home/foo/enhydris/venv/bin/pip install  isort flake8 black 
RUN /home/foo/enhydris/venv/bin/pip install  pillow

# switch USER
USER postgres

# Adjust PostgreSQL configuration so that remote connections to the
# database are possible.
RUN echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/11/main/pg_hba.conf

# And add ``listen_addresses`` to ``/etc/postgresql/11/main/postgresql.conf``
RUN echo "listen_addresses='*'" >> /etc/postgresql/11/main/postgresql.conf

# Expose the PostgreSQL port
EXPOSE 5432
EXPOSE 8000

# Create a PostgreSQL role named ``enhydris`` with ``enhydris`` as the password and
# then create a database `enhydris` owned by the ``enhydris`` role and add
# the postgis extension


RUN    /etc/init.d/postgresql start &&\
    psql --command "CREATE USER openmeteo WITH SUPERUSER PASSWORD 'topsecret';" &&\
    createdb -O openmeteo openmeteo &&\
    psql -d openmeteo --command "CREATE EXTENSION IF NOT EXISTS postgis;" &&\
    psql -d openmeteo --command "CREATE EXTENSION IF NOT EXISTS postgis_topology;" 


COPY ./local.py /home/foo/enhydris/enhydris_project/settings
# Add VOLUMEs to allow backup of config, logs and databases
VOLUME  ["/etc/postgresql", "/var/log/postgresql", "/var/lib/postgresql", "/home/foo"]

# Set the default command to run when starting the container
#RUN ["service", "postgresql", "start"]
USER root
#CMD ["/usr/lib/postgresql/11/bin/postgres", "-D", "/var/lib/postgresql/11/main", "-c", "config_file=/etc/postgresql/11/main/postgresql.conf"]
#
#ENTRYPOINT ["service","postgresql","start"]
#CMD ["service","postgresql","start"]
#CMD ["/home/foo/enhydris/venv/bin/python","./manage.py","makemigrations","--check"]

#CMD ["/home/foo/enhydris/venv/bin/python","./manage.py"]

#CMD ["/home/foo/enhydris/venv/bin/python","./manage.py","runserver","0.0.0.0:8000"]
ADD start.sh /
RUN chmod +x /start.sh

CMD ["/start.sh"]

