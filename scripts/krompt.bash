

#### K-PROMPT START

NORMAL="\[\033[00m\]"
BLUE="\[\033[01;34m\]"
YELLOW="\[\e[1;33m\]"
GREEN="\[\e[1;32m\]"

__kube_ps1()
{
	if [ ! -f $HOME/.kube/config ]; then
       echo "N/A"
    else
    	# Get current context
    	CONTEXT=$(cat ~/.kube/config | grep "current-context:" | sed "s/current-context: //")

  		if [ -n "$CONTEXT" ]; then
        	echo "(${CONTEXT})"
    	fi
    fi
}

export PS1="${BLUE}\W ${GREEN}\$(__kube_ps1)${NORMAL} \$ "

##### K-PROMPT END
