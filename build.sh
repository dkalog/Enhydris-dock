set -ex
# SET THE FOLLOWING VARIABLES
# docker hub username
# image name
IMAGE=enhydris
docker build -t $USER/$IMAGE:latest .
