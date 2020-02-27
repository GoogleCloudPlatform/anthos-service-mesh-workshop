
#### K-PROMPT START

NORMAL="\[\033[00m\]"
BOLD="\[\033[1m\]"
BLUE="\[\033[01;34m\]"
YELLOW="\e[38;5;46m"
GREEN="\e[38;5;226m"
#YELLOW="\[\e[0;33m\]"
#GREEN="\[\e[0;32m\]"
LIGHT_CYAN="\e[38;5;87m"

__kube_ps1()
{
    if [ ! -f ${KUBECONFIG} ] || [ -z ${KUBECONFIG} ]; then
       echo "N/A"
    else
        # Get current context
        CONTEXT=$(cat ${KUBECONFIG} | grep "current-context:" | sed "s/current-context: //")
        NAMESPACE=$(kubectl config view -o=jsonpath="{.contexts[?(@.name==\"${CONTEXT}\")].context.namespace}")
        if [ -z $NAMESPACE ]; then NAMESPACE="default"; fi

                if [ -n "$CONTEXT" ]; then
                echo "(${CONTEXT} in ${NAMESPACE} namespace)"
        fi
    fi
}

__gcp_project()
{
        if [ -z $DEVSHELL_PROJECT_ID ]; then GCP_PROJECT_ID="N/A"; else GCP_PROJECT_ID=$DEVSHELL_PROJECT_ID; fi
        echo $GCP_PROJECT_ID
}

# export PS1="│\$(date +%d\-%b\ %H:%M) ${BLUE}\w ${GREEN}⎈$(__kube_ps1)${YELLOW} Ⴤ$(__git_ps1 "(%s)") ${NORMAL}ക \n└─⪧ "
export PS1="│\$(date +%d\-%b\ %H:%M) ${LIGHT_CYAN}\u in ⎔ \$(__gcp_project) ⪧ \w ${GREEN}⎈\$(__kube_ps1)${YELLOW} Ⴤ [\$(git branch 2>/dev/null | grep "^*" | colrm 1 2)] ${NORMAL}ക \n└─⪧ "


##### K-PROMPT END

