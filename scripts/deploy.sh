#!/usr/bin/bash

#==============================================================================
#Title          : deploy.sh
#Description    : This script will deploy Vepolink cloudformation template to setup AWS Infrastructure.
#Author		    : Gunjan Shah
#Date           : 5 JUL 2021
#==============================================================================
# DECLARATION OF GLOBAL VARIBALES
#==============================================================================
service='Vepolink'
capabilities=CAPABILITY_NAMED_IAM
region=ap-south-1
formation_type="create-stack"
poll_type="stack-create-complete"
role_arn="arn:aws:iam::828206008857:role/vplk-deploy-role-<ENV>"

today_date=$(date +%d%m%Y)

usage() {
    echo "Usage: deploy.sh -e <ENV_NAME> -t <TEMPLATE_FILE> -s <STACK_NAME> -r <REGION_NAME> -g <TAG_FILE>"
}


get_stack_name() {
    filename=$(basename "$1")
    filename="${filename%.*}"
    echo 'vplk-'$filename'-'$2
}


# The purpose of this subroutine is to create a new cloudformation stack.
createstack() {

 stack=$1
 templ="--template-body file://$2"
 tags="--tags file://$3"

 role_arn1=$(echo "$role_arn" | sed "s/<ENV>/$env_name/g")

 aws cloudformation ${formation_type} --role-arn $role_arn1 --stack-name ${stack} ${templ} --capabilities ${capabilities} --region ${region} ${tags}

}

##########################################
# MAIN
##########################################

# Entry Point

while getopts ":e:t:g:" opt; do
    case "${opt}" in
        e) env_name=${OPTARG}
           ;;
        t) template=${OPTARG}
           ;;
        g) tag_file=${OPTARG}
           ;;
    esac
done

# Validate inputs
if [ -z ${env_name} ] || [ -z ${template} ] || [ -z ${tag_file} ]
then
    usage
    exit 1
else
    echo "$today_date: Vepolink AWS Components creation process..."

    file=`ls -1 $template/param*.yaml`
    stack=$(get_stack_name $file $env_name)

    echo "$today_date: Creating stack: --stack-name ${stack} for cloudformation template $file"

    createstack $stack ${file} $tag_file

fi