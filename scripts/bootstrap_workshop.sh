#!/usr/bin/env bash

# Copyright 2019 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Take input no of users, workshop number, ORG_ID, BILLING_ID
# TF_VAR_org_id, TF_VAR_billing_account, MY_USER
# RANDOM_PERSIST is YYMMDD-workshop_number

if [[ $OSTYPE != "linux-gnu" ]]; then
    echo "ERROR: This script and consecutive set up scripts have only been tested on Linux. Currently, only Linux (debian) is supported. Please run in Cloud Shell or in a VM running Linux".
    exit;
fi

usage()
{
   echo ""
   echo "Usage: $0"
   echo -e "\t--set-up-for-admin | -sufa Boolean flag to set up for admin user currently logged in to gcloud. If present, --start-user-num and --end-user-num are ignored and only 1 set up is created."
   echo -e "\t--org-name | -on Name of Organization"
   echo -e "\t--billing-id | -bi  Billing Account ID. User must have admin permissions on account."
   echo -e "\t--workshop_num | -wn 2 digit workshop identifying number with leading zero. Start with 01 for first workshop in a day and increment as needed."
   echo -e "\t--start-user-num | -sun start of sequence for users to be created. Example: If you want to create users 018 to 024 pass 18 for this argument."
   echo -e "\t--end-user-num | -eun end of sequence for users to be created. Example: If you want to create users 018 to 024 pass 24 for this argument."
   echo -e "\t--admin-gcs-bucket | -agb Admin GCS bucket containing file with list of tf admin projects. Do not include gs:// prefix."

   exit 1 # Exit script after printing help
}

# Setting default empty values
SETUP_ADMIN=false
WORKSHOP_NUM=
START_USER_NUM=
END_USER_NUM=
ORG_NAME=
ADMIN_GCS_BUCKET=
BILLING_ID=

while [ "$1" != "" ]; do
    case $1 in
        --set-up-for-admin | -sufa )  shift
                                      SETUP_ADMIN=true
                                      ;;
        --org-name | -on )            shift
                                      ORG_NAME=$1
                                      ;;
        --billing-id | -bi )          shift
                                      BILLING_ID=$1
                                      ;;
        --workshop-num | -wn )        shift
                                      WORKSHOP_NUM=$1
                                      ;;
        --start-user-num | -sun )     shift
                                      [[ $SETUP_ADMIN = true ]] && START_USER_NUM=1 || START_USER_NUM=$1
                                      ;;
        --end-user-num | -eun )       shift
                                      [[ $SETUP_ADMIN = true ]] && END_USER_NUM=1 || END_USER_NUM=$1
                                      ;;
        --admin-gcs-bucket | -agb)    shift
                                      ADMIN_GCS_BUCKET=$1
                                      ;;
        --help | -h )                 usage
                                      exit
    esac
    shift
done

[[ $SETUP_ADMIN = true ]] && { END_USER_NUM=1; START_USER_NUM=1; }

# Validate WORKSHOP_NUM is 2 characters
[ ${WORKSHOP_NUM} ] & [ ${#WORKSHOP_NUM} = 2 ] || { echo "workshop-num must be exactly 2 characters."; exit; }

# Validate START_USER_NUM and END_USER_NUM are numbers
# Also that START comes before END or is the same number
if [[ $SETUP_ADMIN = false ]]; then
  [[ ${START_USER_NUM} =~ ^[0-9]+$ && ${END_USER_NUM} =~ ^[0-9]+$ ]] || { echo "START_USER_NUM and END_USER_NUM must be numbers."; exit; }
  [ ${END_USER_NUM} -ge ${START_USER_NUM} ] || { echo "END_USER_NUM must be greater than or equal to START_USER_NUM."; exit; }
  [[ ${START_USER_NUM} -le 999 && ${END_USER_NUM} -le 999 ]] || { echo "START_USER_NUM and END_USER_NUM must be less than 999."; exit; }
fi

# Validate ORG_NAME exists
[[ ${ORG_NAME} ]] || { echo "org-name required."; exit; }
ORG_ID=$(gcloud organizations list \
  --filter="display_name=${ORG_NAME}" \
  --format="value(ID)")
[ ${ORG_ID} ] || { echo "org-name does not exist or you do not have correct permissions in this org."; exit; }

# Validate active user is org admin
# TODO: use this in clean up script instead
export ADMIN_USER=$(gcloud config get-value account)
gcloud organizations get-iam-policy $ORG_ID --format=json | \
jq '.bindings[] | select(.role=="roles/resourcemanager.organizationAdmin")' | grep $ADMIN_USER  &>/dev/null

[[ $? -eq 0 ]] || { echo "Active user is not an organization admin in $ORG_NAME"; exit; }

WORKSHOP_ID="$(date '+%y%m%d')-${WORKSHOP_NUM}"
export SCRIPT_DIR=$(dirname $(readlink -f $0 2>/dev/null) 2>/dev/null || echo "${PWD}/$(dirname $0)")

# Validate ADMIN_GCS_BUCKET
# Also check for existing file in bucket and ask user for input
[[ ${ADMIN_GCS_BUCKET} ]] || { echo "admin-gcs-bucket is required."; exit; }
mkdir -p ${SCRIPT_DIR}/../tmp

gsutil ls gs://${ADMIN_GCS_BUCKET}/${ORG_NAME}/${WORKSHOP_ID}/workshop.txt &>/dev/null

if [ $? -eq 0 ]; then
  # Allow for appending for creating multiple users in the same workshop using multiple runs of the script.
  echo "Workshop folder already contains workshop.txt file. Overwrite or append? (o/a) > "
        read response
        if [ "$response" = "o" ]; then
            # Initialize empty file -- assuming prior run cleaned up
            touch ${SCRIPT_DIR}/../tmp/workshop.txt
        elif [ "$response" = "a" ]; then
            gsutil cp gs://${ADMIN_GCS_BUCKET}/${ORG_NAME}/${WORKSHOP_ID}/workshop.txt ${SCRIPT_DIR}/../tmp/workshop.txt
        else
            echo "Unknown response. Only 'o' or 'a' accepted. Exiting..."
            exit
        fi
else
  touch ${SCRIPT_DIR}/../tmp/workshop.txt
fi

# Validate BILLING_ID
[[ ${BILLING_ID} ]] || { echo "billing-id is required."; exit; }
# Validate active user is billing admin for billing account
gcloud beta billing accounts get-iam-policy $BILLING_ID --format=json | \
jq '.bindings[] | select(.role=="roles/billing.admin")' | grep $ADMIN_USER &>/dev/null

[[ $? -eq 0 ]] || { echo "Active user is not an billing account billing admin in $BILLING_ID"; exit; }

export TF_VAR_org_id=$ORG_ID

export TF_VAR_billing_account=$BILLING_ID

for i in $(seq ${START_USER_NUM} ${END_USER_NUM})
do
  USER_ID=$(printf "%03d" $i)
  export MY_USER="user${USER_ID}@${ORG_NAME}" && [[  $SETUP_ADMIN = true ]] && MY_USER=$ADMIN_USER
  export RANDOM_PERSIST=${WORKSHOP_ID}
  echo "RANDOM PERSIST: ${RANDOM_PERSIST} - MY_USER: ${MY_USER} - ADMIN_USER: ${ADMIN_USER}"
  source $SCRIPT_DIR/setup-terraform-admin-project.sh
  echo "TF_ADMIN: ${TF_ADMIN}"
  echo "$TF_ADMIN" | tee -a ${SCRIPT_DIR}/../tmp/workshop.txt

  # ************************
  # Clean Up
  # ************************
  rm -rf ${SCRIPT_DIR}/../vars
  cd infrastructure
  git remote remove infra
  cd ..

  # Clean up backends and shared states for each GCP prod resource
  for idx in ${!folders[@]}
  do
      # Extract the resource name from the folder
      resource=$(echo ${folders[idx]} | grep -oP '([^\/]+$)')

      # clean up backends
      rm infrastructure/${folders[idx]}/backend.tf

      # clean up shared states for every resource
      rm infrastructure/gcp/prod/shared_states/shared_state_${resource}.tf

      # clean up vars
      tfvar_tmpl_file=infrastructure/${folders[idx]}/terraform.tfvars_tmpl
      if [ -f "$tfvar_tmpl_file" ]; then
          rm infrastructure/${folders[idx]}/terraform.tfvars
      fi

      # clean up vars
      auto_tfvar_tmpl_file=infrastructure/${folders[idx]}/variables.auto.tfvars_tmpl
      if [ -f "$auto_tfvar_tmpl_file" ]; then
          rm infrastructure/${folders[idx]}/variables.auto.tfvars
      fi

  done

done

# Update GCS with workshop.txt
gsutil cp ${SCRIPT_DIR}/../tmp/workshop.txt gs://${ADMIN_GCS_BUCKET}/${ORG_NAME}/${WORKSHOP_ID}/workshop.txt
rm ${SCRIPT_DIR}/../tmp/workshop.txt
