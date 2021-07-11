#!/usr/bin/bash

#==============================================================================
#Title          : config_scripts.sh.sh
#Description    : This script will deploy script on ec2 box to be run as background process.
#Author		    : Gunjan Shah
#Date           : 11 JUL 2021
#==============================================================================
# DECLARATION OF GLOBAL VARIBALES
#==============================================================================
service='Vepolink'
region=ap-south-1
bucket_prefix='vplk-code-'$region

VPLK_LOG_FILE=/tmp/vplk-config-scripts.log

today_date=$(date +%d%m%Y)

usage() {
    echo "Usage: bash scripts/config_scripts.sh.sh -e <ENV_NAME>"
}

configure_csv_code() {

    bucket_name=$1
    ec2_dir=$2

    for file in `aws s3 ls s3://vplk-code-ap-south-1-dev/vplk_scripts/`; do
     if [[ $file =~ 'csv' ]]
     then
      echo "$today_date: Copying the file $file to ${ec2_dir} location..." >> ${VPLK_LOG_FILE}
      stderr=$((aws s3 cp s3://$bucket_name/vplk_scripts/$file $ec2_dir) 2>&1)
      chmod 755 $ec2_dir/$file
     fi
    done

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
    configure_csv_code $bucket_prefix-$env_name /etc/scripts

fi