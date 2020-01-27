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

helpFunction()
{
   echo ""
   echo "Usage: $0 -workshop-id parameterA -admin-gcs-bucket parameterB"
   echo -e "\t--workshop-id Workshop ID that needs to be cleaned up. Example: '200120-01'"
   echo -e "\t--admin-gcs-bucket Admin GCS bucket containing file with list of tf admin projects. Do not include gs:// prefix."
   exit 1 # Exit script after printing help
}

# Setting default empty values
ADMIN_GCS_BUCKET=
WOKRSHOP_ID=

while [ "$1" != "" ]; do
    case $1 in
        --admin-gcs-bucket | -agb)    shift
                                      ADMIN_GCS_BUCKET=$1
                                      ;;
        --workshop-id | -wi )         shift
                                      ADMIN_GCS_BUCKET=$1
                                      ;;
        --help | -h )                 helpFunction
                                      exit
    esac
    shift
done

echo $ADMIN_GCS_BUCKET

exit

export SCRIPT_DIR=$(dirname $(readlink -f $0 2>/dev/null) 2>/dev/null || echo "${PWD}/$(dirname $0)")

# Check if workshop.txt containing tf projects list for clean up exists on ADMIN_GCS_BUCKET
# Exit if it does not exists
gsutil ls gs://${ADMIN_GCS_BUCKET}/${WORKSHOP_ID}
if [ $? -eq 1 ]; then
  echo "gs://${ADMIN_GCS_BUCKET}/${WORKSHOP_ID} does not exist. Exiting..."
  exit
fi

# Copy workshop.txt to tmp
gsutil cp gs://${ADMIN_GCS_BUCKET}/${WORKSHOP_ID}/workshop.txt ${SCRIPT}/../tmp/workshop.txt

# Loop over tf admin projects and copy vars file to clean up projects
while read user_tf_project; do
  export VARS_FILE="${SCRIPT_DIR}/../vars/vars_${user_tf_project}.sh"
  gsutil cp gs://${user_tf_project}/vars/vars.sh ${VARS_FILE}
  source ${SCRIPT_DIR}/cleanup_projects.sh
  unset VARS_FILE
done <${SCRIPT}/../tmp/workshop.txt