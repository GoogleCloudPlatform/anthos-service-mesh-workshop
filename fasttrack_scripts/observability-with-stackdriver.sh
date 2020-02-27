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
title_no_wait "*** Lab: Observability with Stackdriver ***"
echo -e "\n"

# https://codelabs.developers.google.com/codelabs/anthos-service-mesh-workshop/#6
title_no_wait "Install the istio to stackdriver config file in the ops clusters."
title_and_wait "Recall that the Istio controlplane (including istio-telemetry) is installed in the ops clusters only."
print_and_execute "cd ${WORKDIR}/k8s-repo/gke-asm-1-r1-prod/istio-telemetry"
print_and_execute "kustomize edit add resource istio-telemetry.yaml"
print_and_execute " "
print_and_execute "cd ${WORKDIR}/k8s-repo/gke-asm-2-r2-prod/istio-telemetry"
print_and_execute "kustomize edit add resource istio-telemetry.yaml"

title_and_wait "Commit the changes to to k8s-repo."
print_and_execute "cd ${WORKDIR}/k8s-repo"
print_and_execute "git add . && git commit -am \"Install istio to stackdriver configuration\""
print_and_execute "git push"
 
echo -e "\n"
title_no_wait "View the status of the Ops project Cloud Build in a previously opened tab or by clicking the following link: "
echo -e "\n"
title_no_wait "https://console.cloud.google.com/cloud-build/builds?project=${TF_VAR_ops_project_name}"
title_no_wait "Waiting for Cloud Build to finish..."

BUILD_STATUS=$(gcloud builds describe $(gcloud builds list --project ${TF_VAR_ops_project_name} --format="value(id)" | head -n 1) --project ${TF_VAR_ops_project_name} --format="value(status)")
while [[ "${BUILD_STATUS}" =~ WORKING|QUEUED ]]; do
    title_no_wait "Still waiting for cloud build to finish. Sleep for 10s"
    sleep 10
    BUILD_STATUS=$(gcloud builds describe $(gcloud builds list --project ${TF_VAR_ops_project_name} --format="value(id)" | head -n 1) --project ${TF_VAR_ops_project_name} --format="value(status)")
done

echo -e "\n"
title_no_wait "Build finished with status: $BUILD_STATUS"
echo -e "\n"

if [[ $BUILD_STATUS != "SUCCESS" ]]; then
  error_no_wait "Build unsuccessful. Check build logs at: \n https://console.cloud.google.com/cloud-build/builds?project=${TF_VAR_ops_project_name}. \n Exiting...."
  exit 1
fi
 
title_and_wait "Verify the Istio → Stackdriver integration. Get the Stackdriver Handler CRD."
print_and_execute "kubectl --context ${OPS_GKE_1} get handler -n istio-system"

# actually validate the existence of the stackdriver handler
NUM_SD=`kubectl --context ${OPS_GKE_1} get handler -n istio-system | grep "stackdriver" | wc -l`
if [[ $NUM_SD -eq 0 ]]
then 
    error_no_wait "Stackdriver handler is not deployed in the ops-1 cluster."  
    error_no_wait "Verify the istio-telemetry.yaml file is in the k8s-repo. Exiting script..."
    exit 1
else 
    title_no_wait "Stackdriver handler is deployed in the ops-1 cluster. Continuing..."
fi
echo -e "\n"
 
title_and_wait "Verify that the Istio metrics export to Stackdriver is working. Click the link output from this command:"
echo "https://console.cloud.google.com/monitoring/metrics-explorer?cloudshell=false&project=${TF_VAR_ops_project_name}"
title_no_wait "Clicking on the link sets up a new Stackdriver workspace."
title_and_wait "A Stackdriver Workspace is a tool for monitoring resources contained in one or more Google Cloud projects."
title_no_wait "View a sample Istio metrics Chart by clicking the output of the following link."
title_no_wait "**NOTE: Select the entire link and then paste into an Incognito Chrome tab. Clicking on the link will only open a partial link."
echo -e "\n"
echo -e "${bold}https://console.cloud.google.com/monitoring/metrics-explorer?cloudshell=false&project=${TF_VAR_ops_project_name}&pageState=%7B%22xyChart%22:%7B%22dataSets%22:%5B%7B%22timeSeriesFilter%22:%7B%22filter%22:%22metric.type%3D%5C%22istio.io%2Fservice%2Fserver%2Frequest_count%5C%22%20resource.type%3D%5C%22k8s_container%5C%22%22,%22perSeriesAligner%22:%22ALIGN_RATE%22,%22crossSeriesReducer%22:%22REDUCE_NONE%22,%22secondaryCrossSeriesReducer%22:%22REDUCE_NONE%22,%22minAlignmentPeriod%22:%2260s%22,%22groupByFields%22:%5B%5D,%22unitOverride%22:%221%22%7D,%22targetAxis%22:%22Y1%22,%22plotType%22:%22LINE%22%7D%5D,%22options%22:%7B%22mode%22:%22COLOR%22%7D,%22constantLines%22:%5B%5D,%22timeshiftDuration%22:%220s%22,%22y1Axis%22:%7B%22label%22:%22y1Axis%22,%22scale%22:%22LINEAR%22%7D%7D,%22isAutoRefresh%22:true,%22timeSelection%22:%7B%22timeRange%22:%221h%22%7D%7D${normal}"
echo -e "\n"
title_and_wait "Alternatively, you can generate the same Chart by navigating to the \"Metrics explorer\" link from the left hand menu and searching for \"istio server request count\" in the explorer search bar."

title_no_wait "Add a pre-canned metrics dashboard using the Dashboard API."
title_no_wait "This is typically done as part of a deployment pipeline."
title_no_wait "For this workshop, create the dashboard interacting with the API directly (via curl)."

export OAUTH_TOKEN=$(gcloud auth application-default print-access-token)
export DASHBOARD=$(curl -X GET -H "Authorization: Bearer $OAUTH_TOKEN" -H "Content-Type: application/json" https://monitoring.googleapis.com/v1/projects/${TF_VAR_ops_project_name}/dashboards)

if [[ ${DASHBOARD} == "{}" ]]; then
    print_and_execute "cd ${WORKDIR}/asm/k8s_manifests/prod/app-telemetry/"
    print_and_execute "sed -i 's/OPS_PROJECT/'${TF_VAR_ops_project_name}'/g'  services-dashboard.json"
    print_and_execute "OAUTH_TOKEN=$(gcloud auth application-default print-access-token)"
    print_and_execute "curl -X POST -H \"Authorization: Bearer $OAUTH_TOKEN\" -H \"Content-Type: application/json\" \
                            https://monitoring.googleapis.com/v1/projects/${TF_VAR_ops_project_name}/dashboards \
                            -d @services-dashboard.json "
    else
    title_no_wait "Dashboard already exists. Skipping Dashboard creation."
    echo -e "\n"
fi    

title_and_wait "Navigate to the output link below to view the newly added dashboard."
echo "${bold}https://console.cloud.google.com/monitoring/dashboards/custom/servicesdash?cloudshell=false&project=${TF_VAR_ops_project_name}${normal}"
echo -e "\n"
title_and_wait "Alternatively, you can access the Dashboard by navigating to the \"Dashboard\" link from the left hand menu clicking on \"services dashboard\" from the list of Dashboards."


title_no_wait "Add a new Chart using the API."
title_no_wait "To accomplish this, get the latest version of the Dashboard."
title_no_wait "Apply edits directly to the downloaded Dashboard json."
title_no_wait "And upload the patched json (with the new Chart) using the HTTP PATCH method."
title_and_wait "Get the existing dashboard that was just added:"

print_and_execute "curl -X GET -H \"Authorization: Bearer $OAUTH_TOKEN\" -H \"Content-Type: application/json\" \
    https://monitoring.googleapis.com/v1/projects/${TF_VAR_ops_project_name}/dashboards/servicesdash > ${WORKDIR}/asm/k8s_manifests/prod/app-telemetry/sd-services-dashboard.json"
 
title_no_wait "Add a new Chart for 50th %ile latency to the Dashboard."
title_and_wait "Use jq to patch the downloaded Dashboard json in the previous step with the new Chart."

title_no_wait "Checking to see if the \"Service Average Latencies\" Chart already exists"
export NEW_CHART_EXISTS=$(cat ${WORKDIR}/asm/k8s_manifests/prod/app-telemetry/sd-services-dashboard.json | jq -r '.gridLayout.widgets[] | select(.title=="Service Average Latencies")')
if [[ -z ${NEW_CHART_EXISTS} ]]; then
    title_no_wait "Creating new chart..."
    print_and_execute "export NEW_CHART_JSON=${WORKDIR}/asm/k8s_manifests/prod/app-telemetry/new-chart.json"
    print_and_execute "jq --argjson newChart \"\$(<${NEW_CHART_JSON})\" '.gridLayout.widgets += [\$newChart]' ${WORKDIR}/asm/k8s_manifests/prod/app-telemetry/sd-services-dashboard.json > ${WORKDIR}/asm/k8s_manifests/prod/app-telemetry/patched-services-dashboard.json"
    title_and_wait "Update the Dashboard with the new patched json."
    print_and_execute "curl -X PATCH -H \"Authorization: Bearer $OAUTH_TOKEN\" -H \"Content-Type: application/json\" \
     https://monitoring.googleapis.com/v1/projects/${TF_VAR_ops_project_name}/dashboards/servicesdash \
     -d @${WORKDIR}/asm/k8s_manifests/prod/app-telemetry/patched-services-dashboard.json"
else
    title_no_wait "\"Service Average Latencies\" chart already in the Dashboard. Skipping new chart creation."
    echo -e "\n"
fi
 
title_no_wait "View the dashboard by navigating to the following output link:"
echo "${bold}https://console.cloud.google.com/monitoring/dashboards/custom/servicesdash?cloudshell=false&project=${TF_VAR_ops_project_name}${normal}"
echo -e "\n"
 
title_and_wait "View project logs."
echo "${bold}https://console.cloud.google.com/logs/viewer?cloudshell=false&project=${TF_VAR_ops_project_name}${normal}"
echo -e "\n"
title_and_wait "Refer to the Logging section in the Observability Lab in the workshop for further details."

title_no_wait "View project traces:"
echo "${bold}https://console.cloud.google.com/traces/overview?cloudshell=false&project=${TF_VAR_ops_project_name}${normal}"
echo -e "\n"
title_and_wait "Refer to the Tracing section in the Observability Lab in the workshop for further details."

title_no_wait "Expose Grafana in ops-1 cluster. Grafana is an open source metrics dashboarding tool."
title_no_wait "This is used later in the workshop in the Istio control plane monitoring and troubleshooting sections."
title_and_wait "To learn more about Grafana, visit https://grafana.io"
export PORT_3000_EXPOSED=$(sudo netstat -tulpn | grep LISTEN | grep 3000)
if [[ -z ${PORT_3000_EXPOSED} ]]; then
    print_and_execute "kubectl --context ${OPS_GKE_1} -n istio-system port-forward svc/grafana 3000:3000 >> /dev/null & "
else
    title_no_wait "Grafana already exposed on port 3000."
fi

title_no_wait "Click on the following link to access Grafana dashboards."
echo -e "\n"
echo "${bold}https://ssh.cloud.google.com/devshell/proxy?authuser=0&port=3000&environment_id=default${normal}"

echo -e "\n"
title_no_wait "Congratulations! You have successfully completed the Observability with Stackdriver lab."
echo -e "\n"
