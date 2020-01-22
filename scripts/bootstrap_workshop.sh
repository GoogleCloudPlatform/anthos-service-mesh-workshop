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

# TODO: make this an input
ORG_ADMIN_PROJECT="gcpworkshops-gsuite-admin"

#export TF_VAR_org_id=$1
#export ORG_NAME=$2
#export TF_VAR_billing_account=$3
#export WORKSHOP_NO=$4
#export NUM_USERS=$5

export TF_VAR_billing_account=0109A7-3E7048-9068C9
export TF_VAR_org_id=145197157826

# TODO: args
WORKSHOP_NO="01"
NUM_USERS=2
ORG_NAME="gcpworkshops.com"
ADMIN_GCS_BUCKET="gcpworkshops-gsuite-admin"

WORKSHOP_ID="$(date '+%y%m%d')-${WORKSHOP_NO}"
export SCRIPT_DIR=$(dirname $(readlink -f $0 2>/dev/null) 2>/dev/null || echo "${PWD}/$(dirname $0)")

# use this in clean up script instead
export ADMIN_USER=$(gcloud config get-value account)

gsutil ls gs://${ADMIN_GCS_BUCKET}/${WORKSHOP_ID}
if [ $? -eq 1 ]; then
  rm ${SCRIPT_DIR}/../tmp/workshop.txt
  touch ${SCRIPT_DIR}/../tmp/workshop.txt
fi

# If we want to split creation of users on multiple runs then the start of the sequence needs to be a variable
for i in $(seq 1 $NUM_USERS)
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