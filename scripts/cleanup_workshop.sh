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

# TODO: args
WORKSHOP_NO="01"
ADMIN_GCS_BUCKET="gcpworkshops-gsuite-admin"

WORKSHOP_ID="$(date '+%y%m%d')-${WORKSHOP_NO}"

export SCRIPT_DIR=$(dirname $(readlink -f $0 2>/dev/null) 2>/dev/null || echo "${PWD}/$(dirname $0)")

gsutil ls gs://${ADMIN_GCS_BUCKET}/${WORKSHOP_ID}/workshop.txt
if [ $? -eq 1 ]; then
  echo "gs://${ADMIN_GCS_BUCKET}/${WORKSHOP_ID}/workshop.txt does not exist. Exiting..."
  exit
fi

gsutil cp gs://${ADMIN_GCS_BUCKET}/${WORKSHOP_ID}/workshop.txt ${SCRIPT}/../tmp/workshop.txt

while read user_tf_project; do
  export VARS_FILE="${SCRIPT_DIR}/../vars/vars_${user_tf_project}.sh"
  gsutil cp gs://${user_tf_project}/vars/vars.sh ${VARS_FILE}
  source ${SCRIPT_DIR}/cleanup_projects.sh
  unset VARS_FILE
done <${SCRIPT}/../tmp/workshop.txt