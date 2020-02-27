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

############### FUNCIONS #######################
is_deployment_ready () {
# First check to make sure deployment is created by checking exit code is 0
    kubectl --context $1 -n $2 get deploy $3 &> /dev/null
    export exit_code=$?
    while [ ! " ${exit_code} " -eq 0 ]
        do 
            sleep 5
            echo -e "Waiting for deployment $3 in cluster $1 to be created..."
            kubectl --context $1 -n $2 get deploy $3 &> /dev/null
            export exit_code=$?
        done
    echo -e "Deployment $3 in cluster $1 created."

    # Once deployment is created, check for deployment status.availableReplicas is greater than 0
    export availableReplicas=$(kubectl --context $1 -n $2 get deploy $3 -o json | jq -r '.status.availableReplicas')
    while [[ " ${availableReplicas} " == " null " ]]
        do 
            sleep 5
            echo -e "Waiting for deployment $3 in cluster $1 to become ready..."
            export availableReplicas=$(kubectl --context $1 -n $2 get deploy $3 -o json | jq -r '.status.availableReplicas')
        done
    
    echo -e "$3 in cluster $1 is ready with replicas ${availableReplicas}."
    return ${availableReplicas}
}

is_istio_deployment_ready () {
# First check to make sure deployment is created by checking exit code is 0
    kubectl --context $1 -n istio-system get deploy $2 &> /dev/null
    export exit_code=$?
    while [ ! " ${exit_code} " -eq 0 ]
        do 
            sleep 5
            echo -e "Waiting for deployment $2 in cluster $1 to be created..."
            kubectl --context $1 -n istio-system get deploy $2 &> /dev/null
            export exit_code=$?
        done
    echo -e "Deployment $2 in cluster $1 created."

    # Once deployment is created, check for deployment status.availableReplicas is greater than 0
    export availableReplicas=$(kubectl --context $1 -n istio-system get deploy $2 -o json | jq -r '.status.availableReplicas')
    while [[ " ${availableReplicas} " == " null " ]]
        do 
            sleep 5
            echo -e "Waiting for deployment $2 in cluster $1 to become ready..."
            export availableReplicas=$(kubectl --context $1 -n istio-system get deploy $2 -o json | jq -r '.status.availableReplicas')
        done
    
    echo -e "$2 in cluster $1 is ready with replicas ${availableReplicas}."
    return ${availableReplicas}
}


expose_istio_svc_via_ilb () {

    echo -e "\n${CYAN}Exposing $2 service in cluster $1 using an ILB...${NC}"

    kubectl --context $1 -n istio-system patch svc $2 --patch \
    '{"metadata": {"annotations": {"cloud.google.com/load-balancer-type": "Internal"}}}'
    kubectl --context $1 -n istio-system patch svc $2 --patch \
    '{"spec": {"type": "LoadBalancer"}}'

}

get_istio_svc_ingress_ip () {

    export ingress=$(kubectl --context $1 -n istio-system get svc $2 -o json | jq -r '.status.loadBalancer')
        while [[ " ${ingress} " == " {} " ]]
            do 
                sleep 5
                echo -e "Waiting for service $2 in cluster $1 to get an ILB IP..."
                export ingress=$(kubectl --context $1 -n istio-system get svc $2 -o json | jq -r '.status.loadBalancer')
            done
        export ingress_ip=$(kubectl --context $1 -n istio-system get svc $2 -o json | jq -r '.status.loadBalancer.ingress[].ip')
        echo -e "$2 in cluster $1 has an ILB IP of ${ingress_ip}."


}

title_no_wait () {
    echo "${bold}# ${@}${normal}"
}

title_and_wait () {
    export CYAN='\033[1;36m'
    export YELLOW="\e[38;5;226m"
    export NC='\e[0m'
    echo "${bold}# ${@}"
    echo -e "${YELLOW}--> Press ENTER to continue...${NC}"
    read -p ''
}

print_and_execute () {

    SPEED=130
    GREEN='\e[1;32m' # green
    NC='\e[0m'

    printf "${GREEN}\$ ${@}${NC}" | pv -qL $SPEED;
    printf "\n"
    eval "$@" ;
}

nopv_and_execute () {

    SPEED=130
    GREEN='\e[1;32m' # green
    NC='\e[0m'

    printf "${GREEN}\$ ${@}${NC}";
    printf "\n"
    eval "$@" ;
}

error_no_wait () {
    RED='\e[1;91m' # red
    NC='\e[0m'
    printf "${RED}# ${@}${NC}"
    printf "\n"
}

is_istio_repl_cp_ready () {
    # define ops clusters contexts
    declare -a OPS_CLUSTER_CONTEXTS
    export OPS_CLUSTER_CONTEXTS=(
        ${OPS_GKE_1}
        ${OPS_GKE_2}
    )

    # Define OPS cluster deployments - the full Istio controlplane
    declare -a OPS_ISTIO_DEPLOYMENTS
    export OPS_ISTIO_DEPLOYMENTS=(grafana 
                            istio-citadel 
                            istio-ingressgateway 
                            istio-egressgateway 
                            istio-galley 
                            istio-pilot 
                            istio-policy
                            istio-telemetry
                            istio-tracing
                            istio-sidecar-injector
                            istiocoredns
                            kiali
                            prometheus
                            )

    echo "Waiting until all deployments are ready..."
    for cluster in ${OPS_CLUSTER_CONTEXTS[@]}
        do
            for deployment in ${OPS_ISTIO_DEPLOYMENTS[@]}
                do  
                    echo "for cluster ${cluster} and deployment ${deployment}"
                    is_deployment_ready ${cluster} istio-system ${deployment}
                done 
        done 
    echo "All Istio deployments are ready in ops clusters."
}

export -f is_deployment_ready
export -f expose_istio_svc_via_ilb
export -f get_istio_svc_ingress_ip
export -f print_and_execute
export -f title_no_wait
export -f title_and_wait
export -f error_no_wait
