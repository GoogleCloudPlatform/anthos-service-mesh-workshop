#!/bin/bash

source ${1}/env.sh

log "🐳 Starting ${SVC_NAME} on ${VM_NAME}..."

DOCKER_CMD="sudo docker run -d --name $SVC_NAME -p $SVC_PORT:$SVC_PORT -e "PORT=$SVC_PORT" $IMAGE"

gcloud compute ssh --project ${TF_VAR_dev1_project_name} --zone $VM_ZONE \ -- "${DOCKER_CMD}"

log "✅ Done."