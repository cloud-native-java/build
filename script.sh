#!/bin/bash

export PATH=$PATH:.


# run the tests and deploy the service
#mvn -DskipTests=true -X clean deploy

# deploy to CF
UTILS=$( cd `dirname $0` && pwd )/utils
$UTILS/root-cf-deploy.sh