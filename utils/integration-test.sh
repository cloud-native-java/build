#!/usr/bin/env bash

echo INTEGRATION TEST
set -e

root=`dirname $0`
source $root/common.sh

rm -rf $SKIP_FILE

it_dir=`integration_test_directory $PWD`
echo $it_dir

function integration_test(){
    invoke_file_in_dir $it_dir
    mvn_pom=$it_dir/pom.xml
    [ -f "$mvn_pom" ] && mvn -X -f $mvn_pom clean install  || die "'mvn clean install' failed for integration test" 1
}


[ -d "$it_dir" ] && integration_test || echo "there are no integration tests to run in '$integration_test'"
