#!/bin/bash

source ./build/utils/common.sh


CF_USER=$1
CF_PASSWORD=$2
CF_ORG=$3
CF_SPACE=$4

function install_cf(){
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

mkdir -p $HOME/bin
mvn clean install || die "'mvn clean install' failed" 1
validate_cf
