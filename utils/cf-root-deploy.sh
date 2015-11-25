#!/usr/bin/env bash

set -e

export ROOT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
export SWAP=${SWAP:-$TMPDIR}

$ROOT_DIR/cf-common.sh


function traverse_and_deploy(){

    root=$1

    cmd="";

    find $root -mindepth 1  -maxdepth 1 -type d | while read l; do

        curd=$(cd $l && pwd);

        cmd="";

        script_file=$curd/cf-deploy.sh

        manifest_file=$curd/manifest.yml

        [ -d "${script_file}" ] && cmd="script";

        [ -d "${manifest_file}" ] && cmd="manifest";

        if [ "$cmd" ==  "script" ]
        then
            echo "Trying to do a CF PUSH with a cf-deploy.sh";
            cd $curd && $curd/cf-deploy.sh
        elif [ "$cmd" == "manifest" ]
        then
            echo "Trying to do a CF PUSH with manifest.yml";
            cd $curd && cf push
            traverse_and_deploy $curd
        else
            traverse_and_deploy $curd
        fi
    done

}

function traverse_and_reset(){

    root=$1
    svcs_to_delete_file="${SWAP}services_to_delete_$RANDOM.txt"

    find $root -iname "manifest.yml" -type f | while read l ; do
        app_name=$( cat $l | grep name | cut -f 2 -d: );
        cf d -f $app_name

        $ROOT_DIR/cf-services.py $app_name "`cf oauth-token`" | while read s; do
            echo "$s" >> ${svcs_to_delete_file}
        done
    done

    [ -d "${svcs_to_delete_file}" ] &&  grep -v '^$' ${svcs_to_delete_file} | while read svc ; do
        cf ds -f $svc ;
    done

    rm -rf ${svcs_to_delete_file}

    cf delete-orphaned-routes -f
}




traverse_and_reset $PWD
traverse_and_deploy $PWD

cf services
cf apps

