#!/bin/bash


mkdir -p $HOME/bin

CF_USER=$1
CF_PASSWORD=$2
CF_ORG=$3
CF_SPACE=$4


#mvn -DskipTests=true -X clean install

curl -v -L -o cf.tgz 'https://cli.run.pivotal.io/stable?release=linux64-binary&version=6.13.0&source=github-rel'
tar zxpf cf.tgz

mv cf $HOME/bin

export PATH=$PATH:$HOME/bin


cf api https://api.run.pivotal.io
cf auth $CF_USER $CF_PASSWORD
cf target -o $CF_ORG -s $CF_SPACE
cf apps