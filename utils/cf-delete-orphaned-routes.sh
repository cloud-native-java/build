#!/usr/bin/env bash


## basically, cf delete-orphaned-routes doesn't correctly delete
## routes from route services that are still attached to service instances
## but not apps. this is a bit of a hack script to programatically undo those
## then let cf delete-orphaned-routes do the heavy lifting.

cf auth $CF_USER $CF_PASSWORD
cf target -o $CF_ORG -s $CF_SPACE

token=`cf oauth-token`

`dirname $0`/cf-delete-orphaned-routes.py $token

cf delete-orphaned-routes -f