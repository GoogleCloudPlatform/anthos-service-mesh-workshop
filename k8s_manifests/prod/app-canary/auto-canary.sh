

#!/bin/bash
log() { echo "$1" >&2; }


active_v2_percent () {
 p=`kubectl --context=${OPS_CONTEXT} get virtualservice -n frontend frontend -o json \
 | jq -r '.spec.http[].route[]|select(.destination.subset == "v2") .weight'`

 log "v2 deployed percentage is ${p}%"
 return $p
}


run_canary() {
    PERCENT=$1
    # copy all manifests in canary-${PERCENT}/  to k8s_repo
    cp canary${PERCENT}/*  ${K8S_REPO}/${OPS_DIR}/app-canary/

    # commit to K8s_repo
    cd ${K8S_REPO}/${OPS_DIR}/
    git add .
    git commit -m "Canary deployment - ${PERCENT}% to frontend-v2"
    git push origin master

    cd $CANARY_DIR

    # wait for cloud build to finish
    VAL=$(active_v2_percent $PERCENT)
    ACTIVE_PERCENT=$(echo $?)

    while [[ "${ACTIVE_PERCENT}" != "${PERCENT}" ]]; do
        echo "waiting for build to complete. active percent is ${ACTIVE_PERCENT} and target percent is ${PERCENT}"
        sleep 10
        ACTIVE_PERCENT=$(active_v2_percent $PERCENT)
        echo "end of loop"
    done

    log "✅ ${PERCENT}% successfully deployed"
    return
}


# make sure ops cluster is set
export K8S_REPO="/home/`whoami`/anthos-service-mesh-lab/k8s-repo"
export CANARY_DIR="/home/`whoami`/anthos-service-mesh-lab/asm/k8s_manifests/prod/app-canary"


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

log "🐤 frontend-v2 Canary Complete for ${OPS_DIR} 🌈"