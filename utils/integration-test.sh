#!/usr/bin/env bash

set -e

export ROOT_DIR=`dirname $0`
export SWAP=${SWAP:-$TMPDIR}

source $ROOT_DIR/common.sh
$ROOT_DIR/cf-common.sh

function integration_test(){
    root=$1
    integration_test=$root/`basename $root`-it
    [ -d "$integration_test" ] &&  mvn -f $integration_test/pom.xml clean install || echo "there are no integration tests to run in '$integration_test'" 
}

integration_test `pwd`
