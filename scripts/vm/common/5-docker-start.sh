#!/bin/bash

source ${1}/env.sh

log "🐳 Starting ${SVC_NAME} on ${VM_NAME}..."

DOCKER_RUN_ENV="-e PORT=${SVC_PORT}"
DOCKER_CMD="sudo docker run -d --name $SVC_NAME -p $SVC_PORT:$SVC_PORT -e "PORT=$SVC_PORT" $DOCKER_RUN_ENV $IMAGE"

gcloud compute ssh --project ${TF_VAR_dev1_project_name} --zone $ZONE $SVC_NAME \ -- "${DOCKER_CMD}"

log "✅ Done."