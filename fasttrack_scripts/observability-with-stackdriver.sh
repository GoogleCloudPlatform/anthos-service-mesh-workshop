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

# TASK: This script completes the deploy application section of ASM workshop.

#!/bin/bash

# Verify that the scripts are being run from Linux and not Mac
if [[ $OSTYPE != "linux-gnu" ]]; then
    echo "ERROR: This script and consecutive set up scripts have only been tested on Linux. Currently, only Linux (debian) is supported. Please run in Cloud Shell or in a VM running Linux".
    exit;
fi

# Export a SCRIPT_DIR var and make all links relative to SCRIPT_DIR
export SCRIPT_DIR=$(dirname $(readlink -f $0 2>/dev/null) 2>/dev/null || echo "${PWD}/$(dirname $0)")
export LAB_NAME=observability-with-stackdriver

# Create a logs folder and file and send stdout and stderr to console and log file 
mkdir -p ${SCRIPT_DIR}/../logs
export LOG_FILE=${SCRIPT_DIR}/../logs/ft-${LAB_NAME}-$(date +%s).log
touch ${LOG_FILE}
exec 2>&1
exec &> >(tee -i ${LOG_FILE})

source ${SCRIPT_DIR}/../scripts/functions.sh

# Lab: Observability with Stackdriver

# Set speed
bold=$(tput bold)
normal=$(tput sgr0)

color='\e[1;32m' # green
nc='\e[0m'

echo -e "\n"
echo "${bold}*** Lab: Observability with Stackdriver ***${normal}"
echo -e "\n"

# https://codelabs.developers.google.com/codelabs/anthos-service-mesh-workshop/#6
title_and_wait "Install the istio to stackdriver config file."
print_and_execute "cd ${WORKDIR}/k8s-repo"
print_and_execute " "
print_and_execute "cd gke-asm-1-r1-prod/istio-telemetry"
print_and_execute "kustomize edit add resource istio-telemetry.yaml"
print_and_execute " "
print_and_execute "cd ../../gke-asm-2-r2-prod/istio-telemetry"
print_and_execute "kustomize edit add resource istio-telemetry.yaml"

title_and_wait "Commit to k8s-repo."
print_and_execute "cd ../../"
print_and_execute "git add . && git commit -am \"Install istio to stackdriver configuration\""
print_and_execute "git push"
 
title_and_wait "Wait for rollout to complete."
print_and_execute "../asm/scripts/stream_logs.sh $TF_VAR_ops_project_name"
 
title_and_wait "Verify the Istio → Stackdriver integration Get the Stackdriver Handler CRD."
print_and_execute "kubectl --context ${OPS_GKE_1} get handler -n istio-system"

# actually validate the existence of the stackdriver handler
 
title_and_wait "Verify that the Istio metrics export to Stackdriver is working. Click the link output from this command:"
echo "https://console.cloud.google.com/monitoring/metrics-explorer?cloudshell=false&project=${TF_VAR_ops_project_name}"
echo ""
echo ""
title_and_wait ""

title_and_wait "Now let's add our pre-canned metrics dashboard. \
    We are going to be using the Dashboard API directly.\
    This is something you wouldn't normally do by hand-generating API calls,\
    it would be part of an automation system, or you would build the dashboard manually \
    in the web UI. This will get us started quickly:"
print_and_execute "cd ${WORKDIR}/asm/k8s_manifests/prod/app-telemetry/"
print_and_execute "sed -i 's/OPS_PROJECT/'${TF_VAR_ops_project_name}'/g'  services-dashboard.json"
print_and_execute "OAUTH_TOKEN=$(gcloud auth application-default print-access-token)"
print_and_execute "curl -X POST -H \"Authorization: Bearer $OAUTH_TOKEN\" -H \"Content-Type: application/json\" \
                        https://monitoring.googleapis.com/v1/projects/${TF_VAR_ops_project_name}/dashboards \
                        -d @services-dashboard.json "

title_and_wait "Navigate to the output link below to view the newly added dashboard."
echo "https://console.cloud.google.com/monitoring/dashboards/custom/servicesdash?cloudshell=false&project=${TF_VAR_ops_project_name}"
echo ""
echo ""
title_and_wait ""

title_and_wait "We could edit the dashboard in-place using the UX, but in our case \
    we are going to quickly add a new graph using the API.\
    In order to do that, you should pull down the latest version\
    of the dashboard, apply your edits, then push it back up using the HTTP PATCH method.\
    You can get an existing dashboard by querying the monitoring API.\
    Get the existing dashboard that was just added:"

print_and_execute "curl -X GET -H \"Authorization: Bearer $OAUTH_TOKEN\" -H \"Content-Type: application/json\" \
    https://monitoring.googleapis.com/v1/projects/${TF_VAR_ops_project_name}/dashboards/servicesdash > sd-services-dashboard.json"
 
title_and_wait "Add a new graph: (50th %ile latency): Now we can add a new graph widget \
    to our dashboard in code. This change can be reviewed by peers and checked into version control.\
    Here is a widget to add that shows 50%ile latency (median latency).\
    Try editing the dashboard you just got, adding a new stanza:"
print_and_execute "jq --argjson newChart \"\$(<new-chart.json)\" '.gridLayout.widgets += [$newChart]' sd-services-dashboard.json > patched-services-dashboard.json"
 
title_and_wait "Update the existing servicesdashboard:"
print_and_execute "curl -X PATCH -H \"Authorization: Bearer $OAUTH_TOKEN\" -H \"Content-Type: application/json\" \
     https://monitoring.googleapis.com/v1/projects/${TF_VAR_ops_project_name}/dashboards/servicesdash \
     -d @patched-services-dashboard.json"
 
title_and_wait "View the updated dashboard by navigating to the following output link:"
echo "https://console.cloud.google.com/monitoring/dashboards/custom/servicesdash?cloudshell=false&project=${TF_VAR_ops_project_name}"
 
title_and_wait "View your projects logs:"
echo "https://console.cloud.google.com/logs/viewer?cloudshell=false&project=${TF_VAR_ops_project_name}"

title_and_wait "View your projects traces:"
echo "https://console.cloud.google.com/traces/overview?cloudshell=false&project=${TF_VAR_ops_project_name}"

title_and_wait "Expose Istio in-cluster observability tools, for later use:"
print_and_execute "kubectl --context ${OPS_GKE_1} -n istio-system port-forward svc/grafana 3000:3000 >> /dev/null & "

echo "https://ssh.cloud.google.com/devshell/proxy?authuser=0&port=3000&environment_id=default"

print_and_execute "Done with o11y!"