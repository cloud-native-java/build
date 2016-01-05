#!/usr/bin/env bash

echo INTEGRATION TEST
set -e

root=`dirname $0`
source $root/common.sh

rm -rf $SKIP_FILE

function integration_test(){

    it_dir=`integration_test_directory $PWD`
    invoke_file_in_dir $it_dir
    mvn -f $it_dir/pom.xml clean install
}


[ -d "$it_dir" ] && integration_test || echo "there are no integration tests to run in '$integration_test'"


