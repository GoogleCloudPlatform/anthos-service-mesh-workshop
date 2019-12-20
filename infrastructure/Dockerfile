FROM gcr.io/google.com/cloudsdktool/cloud-sdk:alpine
RUN apk add -u jq python3 openssl

ENV TERRAFORM_VERSION=0.12.18
ENV KUBECTL_VERSION=1.16.1
ENV KUSTOMIZE_VERSION=3.5.3
ENV TF_PLUGIN_CACHE_DIR /workspace/.terraform.d/plugin-cache

# Install terraform
RUN wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    chmod +x terraform && \
    mv terraform /usr/local/bin && \
    rm -rf terraform_${TERRAFORM_VERSION}_linux_amd64.zip

# Install kubectl
RUN wget https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin/

# Install kustomize
RUN wget -O- https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${KUSTOMIZE_VERSION}/kustomize_v${KUSTOMIZE_VERSION}_linux_amd64.tar.gz | \
    tar zxvf - kustomize && \
    chmod +x kustomize && \
    mv kustomize /usr/local/bin