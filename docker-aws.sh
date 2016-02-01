#!/bin/bash
set -e

# Create the volume for persisting container state from AWS CLI
mkdir -p aws-volume
sudo chmod -R 777 aws-volume

create="sh ./aws-create-instance.sh"
delete="sh ./aws-delete-instance.sh"
docker="sh ./ssh-docker-run.sh"
aws="docker run --rm -ti -v $(pwd -P)/aws-volume:/root --env AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID --env AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY --name=aws kbastani/aws"

case $1 in
    create )
        eval "$aws $create";;
    delete )
        eval "$aws $delete" ;;
    docker )
        eval "$aws $docker $2" ;;
esac

export PUBLIC_IP="$(cat ./aws-volume/public_ip)"
export PUBLIC_IP="$(echo $PUBLIC_IP | sed 's/\( -\)//1')"

export SPRING_NEO4J_HOST=$PUBLIC_IP
export SPRING_NEO4J_PORT=7474
export SPRING_DATA_MONGODB_HOST=$PUBLIC_IP
export SPRING_DATA_MONGODB_PORT=27017
export SPRING_REDIS_HOST=$PUBLIC_IP
export SPRING_REDIS_PORT=6379
