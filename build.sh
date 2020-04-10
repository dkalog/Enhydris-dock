set -ex
# SET THE FOLLOWING VARIABLES
# docker hub username
USERNAME=dkalo
# image name
IMAGE=enhydris
docker build -t $USERNAME/$IMAGE:latest .