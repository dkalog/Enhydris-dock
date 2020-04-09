FROM python:3.7-slim-buster
# set environment variables
ADD VERSION .
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# getting postgres
RUN apt-get update && apt-get -y install wget gnupg2 git \
        virtualenv python3-virtualenv python3-pip

RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -

# Add PostgreSQL's repository. It contains the most recent stable release
#     of PostgreSQL, ``11``.
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ buster-pgdg main" > /etc/apt/sources.list.d/pgdg.list

# Install software-properties-common and PostgreSQL 11
#  and some other packages for ftp
RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y \
  wget gnupg2 git virtualenv python3-virtualenv python3-pip \
  software-properties-common \
  postgresql-11 \
  postgresql-client-11 \
  postgresql-contrib-11 \
  postgresql-11-postgis-3 \
  postgresql-11-postgis-3-scripts \
  aptitude  \
  unzip \
  openssh-client \
  openssh-server \
  sshpass \
  && aptitude update \
  && aptitude install -y nano axel wput screen p7zip-full osmium-tool \
  vnstat gdal-bin libgdal-dev \
  rm -rf /var/lib/apt/lists/*
  
  RUN ["git", "clone", "https://github.com/openmeteo/enhydris.git"]
CMD git clone  https://github.com/openmeteo/enhydris.git
WORKDIR /home/foo/enhydris
CMD git checkout master

RUN virtualenv --python=/usr/bin/python3 /home/foo/enhydris
RUN /home/foo/enhydris/bin/pip install gdal==2.4.0
RUN /home/foo/enhydris/bin/pip install -r requirements.txt
RUN /home/foo/enhydris/bin/pip install -r requirements-dev.txt


# switch USER
USER postgres

# Adjust PostgreSQL configuration so that remote connections to the
# database are possible.
RUN echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/11/main/pg_hba.conf

# And add ``listen_addresses`` to ``/etc/postgresql/11/main/postgresql.conf``
RUN echo "listen_addresses='*'" >> /etc/postgresql/11/main/postgresql.conf

# Expose the PostgreSQL port
EXPOSE 5432

# Create a PostgreSQL role named ``enhydris`` with ``enhydris`` as the password and
# then create a database `enhydris` owned by the ``enhydris`` role and add
# the postgis extension

RUN    /etc/init.d/postgresql start &&\
    psql --command "CREATE USER enhydris WITH SUPERUSER PASSWORD 'enhydris';" &&\
    createdb -O enhydris enhydris &&\
    psql -d enhydris --command "CREATE EXTENSION IF NOT EXISTS postgis;" &&\
    psql -d enhydris --command "CREATE EXTENSION IF NOT EXISTS postgis_topology;" &&\
    psql -d enhydris --command "CREATE EXTENSION hstore;" &&\
    psql -d enhydris --command "CREATE SCHEMA import;"


# Add VOLUMEs to allow backup of config, logs and databases
VOLUME  ["/etc/postgresql", "/var/log/postgresql", "/var/lib/postgresql", "/home/osmdata/gpkg"]

# Set the default command to run when starting the container
CMD ["/usr/lib/postgresql/11/bin/postgres", "-D", "/var/lib/postgresql/11/main", "-c", "config_file=/etc/postgresql/11/main/postgresq
l.conf"]


