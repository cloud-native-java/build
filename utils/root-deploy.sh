#!/usr/bin/env bash

echo ROOT TEST

set -e

source `dirname $0`/common.sh

traverse $PWD
