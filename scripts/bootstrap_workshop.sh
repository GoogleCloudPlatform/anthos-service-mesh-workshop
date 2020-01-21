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

#export TF_VAR_org_id=$1
#export ORG_NAME=$2
#export TF_VAR_billing_account=$3
#export WORKSHOP_NO=$4
#export NUM_USERS=$5

export TF_VAR_billing_account=0109A7-3E7048-9068C9
export TF_VAR_org_id=145197157826

WORKSHOP_NO="01"
NUM_USERS=2
ORG_NAME="gcpworkshops.com"

WORKSHOP_ID="$(date '+%y%m%d')-${WORKSHOP_NO}"
export SCRIPT_DIR=$(dirname $(readlink -f $0 2>/dev/null) 2>/dev/null || echo "${PWD}/$(dirname $0)")
echo $SCRIPT_DIR

# use this in clean up script instead
export ADMIN_USER=$(gcloud config get-value account)

for i in $(seq 1 $NUM_USERS)
do
  USER_ID=$(printf "%03d" $i)
  export MY_USER="user${USER_ID}@${ORG_NAME}"
  export RANDOM_PERSIST=${WORKSHOP_ID}
  echo "RANDOM PERSIST: ${RANDOM_PERSIST} - MY_USER: ${MY_USER} - ADMIN_USER: ${ADMIN_USER}"

  $SCRIPT_DIR/setup-terraform-admin-project.sh
  rm -rf ${SCRIPT_DIR}/../vars
  cd infrastructure
  git remote remove infra

done