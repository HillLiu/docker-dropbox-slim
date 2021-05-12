#!/usr/bin/env bash 

MY_PWD=$(pwd)
DOCKER_IMAGE=hillliu/dropbox-slim
DOCKER_CONTAINER_NAME=dropbox

C=''
for i in "$@"; do 
    i="${i//\\/\\\\}"
    C="$C \"${i//\"/\\\"}\""
done

pid=$$

cli='env docker run --rm -it';
cli+=" -v $MY_PWD:$MY_PWD";
cli+=" --name ${DOCKER_CONTAINER_NAME}-${pid} ${DOCKER_IMAGE}"
cli+=" bash ${C}"

bash -c "$cli";
