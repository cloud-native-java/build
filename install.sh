#!/bin/bash



CF_USER=$1
CF_PASSWORD=$2
CF_ORG=$3
CF_SPACE=$4








curl -v -L -o cf.tgz 'https://cli.run.pivotal.io/stable?release=linux64-binary&version=6.13.0&source=github-rel'
tar zxpf cf.tgz


#
./cf api https://api.run.pivotal.io
./cf auth $CF_USER $CF_PASSWORD
./cf target -o $CF_ORG -s $CF_SPACE
./cf apps
#
