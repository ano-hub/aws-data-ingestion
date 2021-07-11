#!/usr/bin/bash

#==============================================================================
#Title          : configure_scripts.sh
#Description    : This script will deploy script on ec2 box to be run as background process.
#Author		    : Gunjan Shah
#Date           : 11 JUL 2021
#==============================================================================
# DECLARATION OF GLOBAL VARIBALES
#==============================================================================
service='Vepolink'
region=ap-south-1
bucket_prefix='vplk-code'

VPLK_LOG_FILE=/tmp/vplk-config_scripts.log

today_date=$(date +%d%m%Y)

usage() {
    echo "Usage: bash scripts/configure_scripts.sh -e <ENV_NAME>"
}

upload_code_onto_s3() {
    bucket_name=$bucket_prefix-$env_name

    vplk_dir=`pwd`/vplk_scripts

    for file in `ls -1 ${vplk_dir}/vplk*.*`; do
      filename=$(basename $file | cut -f 1 -d '.')
      extn=$(basename $file | cut -f 2 -d '.')
      echo "$today_date: uploading the file $file to ${bucket_name} bucket..." >> ${VPLK_LOG_FILE}
      aws s3api put-object --bucket ${bucket_name} --key vplk_scripts/${filename}.$extn --body ${file}
    done
}

get_stack_name() {
    filename=$(basename "$1")
    filename="${filename%.*}"
    echo 'vplk-'$filename'-'$2
}

##########################################
# MAIN
##########################################

# Entry Point

while getopts ":e:" opt; do
    case "${opt}" in
        e) env_name=${OPTARG}
           ;;
    esac
done

# Validate inputs
if [ -z ${env_name} ]
then
    usage
    exit 1
else

    echo "$today_date: Cleaning up the log file..." >> ${VPLK_LOG_FILE}
    if [ -f ${VPLK_LOG_FILE} ]
     then
      rm -f ${VPLK_LOG_FILE}
    fi

    echo "$today_date: Vepolink configuring scripts on EC2 box..." >> ${VPLK_LOG_FILE}
    upload_code_onto_s3

fi