#!/bin/bash

source `dirname $0`/utils/common.sh

export PATH=$PATH:$HOME/bin
export SKIP_FILE=$PWD/skip.txt
export BUILD_DIRECTORY=$( cd `dirname $0` && pwd )

case $5 in
    --docker-aws )
        sh $BUILD_DIRECTORY/docker-aws.sh create
        source $BUILD_DIRECTORY/docker-aws.sh;;
esac

# run the tests and deploy the service
mvn -DskipTests=true clean deploy || die "'mvn clean deploy' failed" 1

# remove and recreate the skip file
rm -rf $SKIP_FILE
echo `integration_test_directory $PWD` > $SKIP_FILE


utils=`dirname $0`/utils
$utils/root-deploy.sh
$utils/integration-test.sh

cf delete-orphaned-routes -f
cf apps
cf services
