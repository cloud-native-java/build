#!/usr/bin/env bash

echo INTEGRATION TEST
set -e

root=`dirname $0`
source $root/common.sh

rm -rf $SKIP_FILE

it_dir=`integration_test_directory $PWD`

[ -d "$it_dir" ] && invoke_file_in_dir $it_dir || echo "there are no integration tests to run in '$integration_test'"


