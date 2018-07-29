#!/bin/sh -x -e
#
# Create compile_openfst Docker image, copy results to this directory and remove the image afterwards
IMAGE=compile_openfst
docker build -t $IMAGE .
CONTAINER_ID=`docker create $IMAGE`
docker cp $CONTAINER_ID:/tmp/compile/openfst+ngram+thrax-mingw32.zip .
docker cp $CONTAINER_ID:/tmp/compile/openfst+ngram+thrax-mingw64.zip .
docker rm -v $CONTAINER_ID
docker rmi $IMAGE

