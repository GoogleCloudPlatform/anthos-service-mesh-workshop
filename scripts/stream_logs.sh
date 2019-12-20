#!/bin/bash

set -e

PROJECT=$1
shift || true

[[ -z "${PROJECT}" ]] && echo "USAGE: $0 <PROJECT>" && exit 1

SCRIPT_DIR=$(dirname $(readlink -f $0 2>/dev/null) 2>/dev/null || echo "${PWD}/$(dirname $0)")

BUILD_ID=$(gcloud builds list --project ${PROJECT} --sort-by=startTime --limit=1 --format='value(id)' | cut -f1)

gcloud builds log --stream --project ${PROJECT} ${BUILD_ID} $@