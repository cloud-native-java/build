#!/usr/bin/env bash


export ROOT_DIR=`dirname $0`
export SWAP=${SWAP:-$TMPDIR}


#yell() { echo "$0: $*" >&2; }
#die() { yell "$*"; exit 111; }
#try() { "$@" || die "cannot $*"; }

function die() {
    [[ $1 ]] || {
        printf >&2 -- 'Usage:\n\tdie <message> [return code]\n'
        [[ $- == *i* ]] && return 1 || exit 1
    }

    printf >&2 -- '%s' "$1"
    exit ${2:-1}
}

function integration_test_directory(){
    root=$1
    echo $1/`basename $root`-it
}

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
        if [ -f "$SKIP_FILE" ]
        then
            cat $SKIP_FILE | grep $l 1>/dev/null  && echo "skipping $l" ||  invoke_file_in_dir $l
        fi
    done
}

function traverse_and_reset(){

    start=$1
    svcs_to_delete_file="${SWAP}services_to_delete_$RANDOM.txt"

    find $start -iname "manifest.yml" -type f | while read l ; do

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

    # this logic gets more involved when we have route services

    cf delete-orphaned-routes -f # this is the problem
}

function traverse(){
    traverse_and_reset $1
    invoke_file_in_dir $1
}
