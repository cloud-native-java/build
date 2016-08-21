#!/bin/bash

source `dirname $0`/utils/common.sh

export PATH=$PATH:$HOME/bin
export SKIP_FILE=$PWD/skip.txt
export BUILD_DIRECTORY=$( cd `dirname $0` && pwd )

# run the tests and deploy the service
#mvn -DskipTests=true clean deploy || die "'mvn clean deploy' failed" 1
mvn -DskipTests=true clean install || die "'mvn clean deploy' failed" 1
# TODO uncomment the above line

# remove and recreate the skip file
rm -rf $SKIP_FILE
echo `integration_test_directory $PWD` > $SKIP_FILE

utils=`dirname $0`/utils

$utils/cf-delete-orphaned-routes.sh

$utils/root-deploy.sh
$utils/integration-test.sh

#$utils/cf-delete-orphaned-routes.sh

cf apps
cf services
