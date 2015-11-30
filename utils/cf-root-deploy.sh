#!/usr/bin/env bash

set -e

export ROOT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
export SWAP=${SWAP:-$TMPDIR}

$ROOT_DIR/cf-common.sh

function invoke_file_in_dir(){

    # if the sh script exists, invoke it.
    # if it doesn't exist, invoke cf push

    curd=$(cd $1 && pwd);

    cmd="";
    script_file=$curd/deploy.sh
    manifest_file=$curd/manifest.yml

    if [ -f "${script_file}" ]
    then
        echo "deploy.sh: ${script_file}";
        cd $curd && $script_file
    elif [ -f "${manifest_file}" ]
    then
        echo "manifest.yml: ${manifest_file}";
        cd $curd && cf push
        traverse_and_deploy $curd
    else
        traverse_and_deploy $curd
    fi


}

function traverse_and_deploy(){

    root=$1

    find $root -mindepth 1 -maxdepth 1 -type d | while read l; do
        invoke_file_in_dir $l
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
invoke_file_in_dir $PWD
#traverse_and_deploy $PWD

cf services
cf apps

