

#!/bin/bash

set -euo pipefail
log() { echo "$1" >&2; }


active_v2_percent () {
 p=`kubectl --context=${OPS_CONTEXT} get virtualservice -n default frontend -o json \
 | jq -r '.spec.http[].route[]|select(.destination.subset == "v2") .weight'`

 log "v2 deployed percentage is ${p}%"
 return $p
}


run_canary() {
    PERCENT=$1
    # copy all manifests in canary-${PERCENT}/  to k8s_repo
    cp canary${PERCENT}/*  ../k8s_repo/${OPS_DIR}/app-canary/

    # commit to K8s_repo
    cd ../k8s_repo/${OPS_DIR}/
    git add .
    git commit -m "Canary deployment - ${PERCENT}% to frontend-v2"
    git push origin master

    cd ../k8s_manifests/prod/app-canary/

    # wait for cloud build to finish
    ACTIVE_PERCENT=$(active_v2_percent $PERCENT)

    while [ $ACTIVE_PERCENT != $PERCENT ]; do
        echo "waiting for build to complete..."
        sleep 2
        ACTIVE_PERCENT=$(active_v2_percent $PERCENT)
    done

    log "✅ ${PERCENT}% successfully deployed"
}


# make sure ops cluster is set
if [ -z "$OPS_DIR" ]
then
    log "You must set OPS_DIR to continue."
    exit
else
    OPS_DIR=$OPS_DIR
fi

if [ -z "$OPS_CONTEXT" ]
then
    log "You must set OPS_CONTEXT to continue."
    exit
else
    OPS_CONTEXT=$OPS_CONTEXT
fi

log "🐤 Starting frontend canary, OPS_DIR=${OPS_DIR}"
declare -a percentages=("20" "50" "80" "100")

for i in "${percentages[@]}"
do
    echo "Starting rollout - ${i}% to v2"
    run_canary ${i}
done
