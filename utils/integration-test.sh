#!/usr/bin/env bash

set -e

export ROOT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
export SWAP=${SWAP:-$TMPDIR}

$ROOT_DIR/cf-common.sh

function integration_test(){
    root=$1
    integration_test=$root/`basename $root`-it
    [ -d "$integration_test" ] &&  mvn -f $integration_test/pom.xml clean install || echo "there are no integration tests in '$integration_test'"

}

integration_test `pwd`