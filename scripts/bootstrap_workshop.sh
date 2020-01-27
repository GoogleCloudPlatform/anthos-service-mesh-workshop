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

set -e

helpFunction()
{
   echo ""
   echo "Usage: $0 --admin-gcs-path parameterA"
   echo -e "\t--admin-gcs-path Path to text file in Admin GCS bucket containing list of tf admin projects. Do not include gs:// prefix. Example: 'WORKSHOP_BUCKET/workshop.txt'"
   exit 1 # Exit script after printing help
}

# Setting default empty values
WORKSHOP_NUM=
START_USER_NUM=
END_USER_NUM=
ORG_NAME=
ADMIN_GCS_BUCKET=
BILLING_ID=

while [ "$1" != "" ]; do
    case $1 in
        --org-name | -on )            shift
                                      ORG_NAME=$1
                                      ;;
        --billing-id | -bi )          shift
                                      BILLING_ID=$1
                                      ;;
        --workshop_num | -wn )        shift
                                      WORKSHOP_NUM=$1
                                      ;;
        --start-user-num | -sun )     shift
                                      START_USER_NUM=$1
                                      ;;
        --end-user-num | -eun )       shift
                                      END_USER_NUM=$1
                                      ;;
        --admin-gcs-bucket | -agb)    shift
                                      ADMIN_GCS_BUCKET=$1
                                      ;;
        --help | -h )                 helpFunction
                                      exit
    esac
    shift
done

# TODO: input validation
# Validate WORKSHOP_NUM is 2 characters
[ ${#WORKSHOP_NUM} = 2 ] || echo "workshop-num must be exactly 2 characters."

# Validate START_USER_NUM and END_USER_NUM are numbers
# Also that START comes before END or is the same number
[[ ${START_USER_NUM} =~ ^[0-9]+$ && ${END_USER_NUM} =~ ^[0-9]+$ ]] || echo "START_USER_NUM and END_USER_NUM must be numbers."
[ ${END_USER_NUM} -ge ${START_USER_NUM} ] || echo "END_USER_NUM must be greater than or equal to START_USER_NUM."

# Validate ORG_NAME exists
ORG_ID = $(gcloud organizations list \
  --filter="display_name=cloud-pharaoh.com" \
  --format="value(ID)")
[ ${ORG_ID} ] || echo "org-name does not exist or you do not have correct permissions in this org."

# Validate ADMIN_GCS_BUCKET
gsutil ls gs://${ADMIN_GCS_BUCKET}/${WORKSHOP_ID}
if [ $? -eq 1 ]; then
  rm ${SCRIPT_DIR}/../tmp/workshop.txt
  touch ${SCRIPT_DIR}/../tmp/workshop.txt
else
  echo "Workshop folder already exists. Exiting..."
  exit
fi

# Validate BILLING_ID

export SCRIPT_DIR=$(dirname $(readlink -f $0 2>/dev/null) 2>/dev/null || echo "${PWD}/$(dirname $0)")

export TF_VAR_org_id=ORG_ID

export TF_VAR_billing_account=${BILLING_ID}

WORKSHOP_ID="$(date '+%y%m%d')-${WORKSHOP_NUM}"

# use this in clean up script instead
export ADMIN_USER=$(gcloud config get-value account)

gsutil ls gs://${ADMIN_GCS_BUCKET}/${WORKSHOP_ID}
if [ $? -eq 1 ]; then
  rm ${SCRIPT_DIR}/../tmp/workshop.txt
  touch ${SCRIPT_DIR}/../tmp/workshop.txt
else
  echo "Workshop folder already exists. Exiting..."
  exit
fi

# If we want to split creation of users on multiple runs then the start of the sequence needs to be a variable
for i in $(seq ${START_USER_NUM} ${END_USER_NUM})
do
  USER_ID=$(printf "%03d" $i)
  export MY_USER="user${USER_ID}@${ORG_NAME}"
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
gsutil cp ${SCRIPT_DIR}/../tmp/workshop.txt gs://${ADMIN_GCS_BUCKET}/${WORKSHOP_ID}/workshop.txt