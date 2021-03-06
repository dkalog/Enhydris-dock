# use of an ubuntu base for simplicity and transparency
FROM python:3.7-slim-buster
# set environment variables
ADD VERSION .
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# getting postgres
RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y wget gnupg2 

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


ADD ./openmeteo.dump /home/foo/enhydris 

RUN    /etc/init.d/postgresql start &&\
    psql --command "CREATE USER openmeteo WITH SUPERUSER PASSWORD 'topsecret';" &&\
    createdb -O openmeteo openmeteo &&\
    psql -d openmeteo --command "CREATE EXTENSION IF NOT EXISTS postgis;" &&\
    psql -d openmeteo --command "CREATE EXTENSION IF NOT EXISTS postgis_topology;" &&\
    psql -d openmeteo --command "\i /home/foo/enhydris/openmeteo.dump"


VOLUME  ["/etc/postgresql", "/var/log/postgresql", "/var/lib/postgresql", "/home/foo"]
COPY ./local.py /home/foo/enhydris/enhydris_project/settings

# Set the default command to run when starting the container
#RUN ["service", "postgresql", "start"]
USER root

ADD start.sh /home/foo/enhydris
RUN chmod +x /home/foo/enhydris/start.sh

CMD ["/home/foo/enhydris/start.sh"]

