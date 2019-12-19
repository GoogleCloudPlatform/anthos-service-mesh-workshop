#!/usr/bin/env bash


############### FUNCIONS #######################
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

export -f is_istio_deployment_ready
export -f expose_istio_svc_via_ilb
export -f get_istio_svc_ingress_ip