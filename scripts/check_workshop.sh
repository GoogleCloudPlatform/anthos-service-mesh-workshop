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

usage()
{
   echo ""
   echo "Usage: $0"
   echo -e "\t--org-name | -on Name of Organization"
   echo -e "\t--workshop-id | -wi Workshop ID that needs to be cleaned up. Example: '200120-01'"
   echo -e "\t--admin-gcs-bucket | -agb Admin GCS bucket containing file with list of tf admin projects. Do not include gs:// prefix."
   exit 1 # Exit script after printing help
}

# Setting default empty values
ADMIN_GCS_BUCKET=
WOKRSHOP_ID=

while [ "$1" != "" ]; do
    case $1 in
        --org-name | -on )            shift
                                      ORG_NAME=$1
                                      ;;
        --admin-gcs-bucket | -agb)    shift
                                      ADMIN_GCS_BUCKET=$1
                                      ;;
        --workshop-id | -wi )         shift
                                      WORKSHOP_ID=$1
                                      ;;
        --help | -h )                 usage
                                      exit
    esac
    shift
done

[[ ${ADMIN_GCS_BUCKET} ]] || { echo "admin-gcs-bucket is required."; exit; }
[[ ${WORKSHOP_ID} ]] || { echo "workshop-id is required."; exit; }

[[ ${ORG_NAME} ]] || { echo "org-name required."; exit; }
ORG_ID=$(gcloud organizations list \
  --filter="display_name=${ORG_NAME}" \
  --format="value(ID)")
[ ${ORG_ID} ] || { echo "org-name does not exist or you do not have correct permissions in this org."; exit; }

export SCRIPT_DIR=$(dirname $(readlink -f $0 2>/dev/null) 2>/dev/null || echo "${PWD}/$(dirname $0)")

# Check if workshop.txt containing tf projects list for clean up exists on ADMIN_GCS_BUCKET
# Exit if it does not exists
gsutil ls gs://${ADMIN_GCS_BUCKET}/${ORG_NAME}/${WORKSHOP_ID}/workshop.txt
if [ $? -eq 1 ]; then
  echo "gs://${ADMIN_GCS_BUCKET}/${ORG_NAME}/${WORKSHOP_ID}/workshop.txt does not exist. Exiting..."
  exit
fi

# Copy workshop.txt to tmp
mkdir -p ${SCRIPT_DIR}/../tmp
gsutil cp gs://${ADMIN_GCS_BUCKET}/${ORG_NAME}/${WORKSHOP_ID}/workshop.txt ${SCRIPT_DIR}/../tmp/workshop.txt

# Loop over tf admin projects and copy vars file to clean up projects
while read user_tf_project; do
  export VARS_FILE="${SCRIPT_DIR}/../vars/vars_${user_tf_project}.sh"
  gsutil cp gs://${user_tf_project}/vars/vars.sh ${VARS_FILE} &>/dev/null
  source $VARS_FILE

  echo "Checking $TF_ADMIN........."

  gcloud config set project $TF_ADMIN &>/dev/null
  TF_STATUS=$(gcloud builds describe $(gcloud builds list --format="value(id)" | head -n 1) --format="value(status)")
  if [ $TF_STATUS != "SUCCESS" ]; then
    if [ $TF_STATUS == "WORKING" ] || [ $TF_STATUS == "QUEUED" ]; then
      echo "TF Build still running on $TF_ADMIN - https://console.cloud.google.com/cloud-build/builds?project=${TF_ADMIN}"
    else
      echo "TF Build Failed on $TF_ADMIN - https://console.cloud.google.com/cloud-build/builds?project=${TF_ADMIN}"
    fi
  else
    gcloud config set project $TF_VAR_ops_project_name &>/dev/null
    OPS_STATUS=$(gcloud builds describe $(gcloud builds list --format="value(id)" | head -n 1) --format="value(status)")
    if [ $OPS_STATUS != "SUCCESS" ]; then
      if [ $TF_STATUS == "WORKING" ] || [ $TF_STATUS == "QUEUED" ]; then
        echo "Ops Build still running on $TF_VAR_ops_project_name - https://console.cloud.google.com/cloud-build/builds?project=${TF_VAR_ops_project_name}"
      else
        echo "Ops Build unsuccessful on $TF_VAR_ops_project_name - https://console.cloud.google.com/cloud-build/builds?project=${TF_VAR_ops_project_name}"
      fi
    fi
  fi

  unset VARS_FILE
done <${SCRIPT_DIR}/../tmp/workshop.txt