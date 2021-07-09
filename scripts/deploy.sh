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
    echo "Usage: bash scripts/deploy.sh -e <ENV_NAME>"
}

get_abs_path() {
    dir=$1
    echo `pwd`/$1
}

get_stack_name() {
    filename=$(basename "$1")
    filename="${filename%.*}"
    echo 'vplk-'$filename'-'$2
}


# The purpose of this subroutine is to check whether the stack with the same name already exists.
checkstack() {
 flag=
 stderr=$(( aws cloudformation describe-stacks --stack-name $1 --region $region) 2>&1)
 ret_code=$?
 if [[ $stderr =~ "Stack with id $1 does not exist" && $ret_code -eq 255 ]]
 then
  flag=0
 else
  flag=1
 fi
 echo $flag
}


# The purpose of this subroutine is to create a new cloudformation stack.
createstack() {

 stack=$1
 templ="--template-body file://$2"
 tags="--tags file://$3"

 role_arn1=$(echo "$role_arn" | sed "s/<ENV>/$env_name/g")

 aws cloudformation ${formation_type} --role-arn $role_arn1 --stack-name ${stack} ${templ} --capabilities ${capabilities} --region ${region} ${tags}
 ret_code=$?
 if [[ $ret_code -eq 0 ]]
 then
  echo "$today_date: Waiting for stack ${stack} create..."
  aws cloudformation wait ${poll_type} --stack-name ${stack} --region ${region}
 fi
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
    echo "$today_date: Vepolink AWS Components creation process..."

    template_dir=$(get_abs_path 'template')
    conf_dir=$(get_abs_path 'conf')
    tag_file=`ls -1 $conf_dir/tags.json`

    template_file=`ls -1 $template_dir/param*.yaml`
    stack=$(get_stack_name $template_file $env_name)

    rc=$(checkstack ${stack_name})

    if [[ $rc -eq 0 ]]
    then
     echo "$today_date: Creating stack: --stack-name ${stack} for cloudformation template $file"
     createstack $stack ${template_file} ${tag_file}
    else
     echo "$today_date: --stack-name ${stack} already exists..."
    fi

    template_file=`ls -1 $template_dir/buckets*.yaml`
    stack=$(get_stack_name $template_file $env_name)

    rc=$(checkstack ${stack_name})

    if [[ $rc -eq 0 ]]
    then
     echo "$today_date: Creating stack: --stack-name ${stack} for cloudformation template $file"
     createstack $stack ${template_file} ${tag_file}
    else
     echo "$today_date: --stack-name ${stack} already exists..."
    fi


fi