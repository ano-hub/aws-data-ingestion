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
crt_formation_type="create-stack"
crt_poll_type="stack-create-complete"
upd_formation_type="update-stack"
upd_poll_type="stack-update-complete"
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

# *****************************************************************************
# The purpose of this subroutine is to create a new cloudformation stack.
# *****************************************************************************
createstack() {

 stack=$1
 templ="--template-body file://$2"
 tags="--tags file://$3"

 role_arn1=$(echo "$role_arn" | sed "s/<ENV>/$env_name/g")

 aws cloudformation ${crt_formation_type} --role-arn $role_arn1 --stack-name ${stack} ${templ} --capabilities ${capabilities} --region ${region} ${tags}
 ret_code=$?
 if [[ $ret_code -eq 0 ]]
 then
  echo "$today_date: Waiting for stack ${stack} create..."
  aws cloudformation wait ${crt_poll_type} --stack-name ${stack} --region ${region}
 fi
}

# *****************************************************************************
# The purpose of this subroutine is to update an existing cloudformation stack.
# *****************************************************************************
updatestack() {

 stack=$1
 templ="--template-body file://$2"
 tags="--tags file://$3"

 flag=0

 stderr=$((create_exec_change_set ${stack} $2) 2>&1)
 ret_code=$?

 if [[ $stderr =~ "No updates are to be performed" && $ret_code -eq 255 ]]
 then
  print("No updates are to be performed")
 elif [[ $ret_code -ne 0 ]]
 then
  print("No updates are to be performed")
 else
  echo "$today_date: Waiting for stack ${stack_name} update..." >> ${DAAS_LOG_FILE}
  aws cloudformation wait ${upd_poll_type} --stack-name ${stack_name} --region ${region}
 fi

}


# *****************************************************************************
# The purpose of this subroutine is to create a changeset with all the changes to be deployed
# on existing Vepolink cloudformation stack and execute that changeset.
# *****************************************************************************

create_exec_change_set() {

 stack=$1
 template=$2
 tags="--tags file://${tag_file}"

 ch_poll_type='change-set-create-complete'

 changesetname='changeset-'$(date +%H%M%S)
 stderr=$(aws cloudformation create-change-set --stack-name $stack --change-set-name $changesetname --change-set-type UPDATE --template-body "file://$template" --capabilities ${capabilities} --region ${region} ${tags})
 ret_code=$?

 echo "$today_date: $stderr while creating changeset $changesetname with return code: $ret_code"

 if [[ $ret_code -eq 0 ]]
 then
  echo "$today_date: Waiting for stack ${changesetname} create/update..."
  stderr=$((aws cloudformation wait ${ch_poll_type} --change-set-name ${changesetname} --stack-name $stack --region ${region}) 2>&1)
  ret_code=$?
  if [[ $ret_code -eq 0 ]]
  then
   echo "$today_date: Executing the changeset $changesetname to update the stack --stack-name $stack"
   stderr=$((aws cloudformation execute-change-set --change-set-name ${changesetname} --stack-name $stack --region ${region}) 2>&1)
  fi
 else
  echo "$today_date: No updates are to be performed for ${changesetname}..."
  #send this to the calling env as stderr
  echo "$today_date: No updates are to be performed for ${changesetname}..."
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

    rc=$(checkstack $stack)

    if [[ $rc -eq 0 ]]
    then
     echo "$today_date: Creating stack: --stack-name ${stack} for cloudformation template $template_file"
     createstack $stack ${template_file} ${tag_file}
    else
     echo "$today_date: --stack-name ${stack} already exists..."
    fi

    template_file=`ls -1 $template_dir/buckets*.yaml`
    stack=$(get_stack_name $template_file $env_name)

    rc=$(checkstack $stack)

    if [[ $rc -eq 0 ]]
    then
     echo "$today_date: Creating stack: --stack-name ${stack} for cloudformation template $template_file"
     createstack $stack ${template_file} ${tag_file}
    else
     echo "$today_date: Updating --stack-name ${stack} for cloudformation template $template_file"
     updatestack $stack ${template_file} ${tag_file}
    fi


fi