#!/bin/bash

source `dirname $0`/utils/common.sh


export PATH=$PATH:$HOME/bin



# run the tests and deploy the service
mvn -DskipTests=true clean deploy || die "'mvn clean deploy' failed" 1

# deploy to CF
UTILS=`dirname $0`/utils
$UTILS/cf-root-deploy.sh
$UTILS/integration-test.sh
