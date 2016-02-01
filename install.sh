#!/bin/bash

source `dirname $0`/utils/common.sh

CF_USER=$1
CF_PASSWORD=$2
CF_ORG=$3
CF_SPACE=$4
DOCKER_AWS=$5

function install_cf(){
    mkdir -p $HOME/bin
    curl -v -L -o cf.tgz 'https://cli.run.pivotal.io/stable?release=linux64-binary&version=6.13.0&source=github-rel'
    tar zxpf cf.tgz
    mkdir -p $HOME/bin && mv cf $HOME/bin
}

function validate_cf(){

    cf  -v || install_cf

    export PATH=$PATH:$HOME/bin

    cf api https://api.run.pivotal.io
    cf auth $CF_USER $CF_PASSWORD
    cf target -o $CF_ORG -s $CF_SPACE
    cf apps
}

function destroy_docker_aws(){
    case $DOCKER_AWS in
        --docker-aws )
          echo "Destroying instance $INSTANCE_ID..."
          sh $BUILD_DIRECTORY/docker-aws.sh delete;;
    esac
}

case $DOCKER_AWS in
    --docker-aws )
        export BUILD_DIRECTORY=$( cd `dirname $0` && pwd )
        sh $BUILD_DIRECTORY/docker-aws.sh create
        source $BUILD_DIRECTORY/docker-aws.sh source

        # Add Neo4j
        sh $BUILD_DIRECTORY/docker-aws.sh docker "run -d -p 7474:7474 -e NEO4J_AUTH=none --name neo4j neo4j:latest"

        # Add MongoDB
        sh $BUILD_DIRECTORY/docker-aws.sh docker "run -d -p 27017:27017 --name mongo mongo:latest"

        # Add Redis
        sh $BUILD_DIRECTORY/docker-aws.sh docker "run -d -p 6379:6379 --name redis redis:latest"

        ;;
esac

mvn clean install || destroy_docker_aws || die "'mvn clean install' failed" 1

case $DOCKER_AWS in
    --docker-aws )
        destroy_docker_aws;;
esac

validate_cf
