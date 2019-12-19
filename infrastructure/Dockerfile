FROM gcr.io/google.com/cloudsdktool/cloud-sdk:alpine
RUN apk add -u jq python3 openssl

ENV TERRAFORM_VERSION=0.12.18
ENV KUBECTL_VERSION=1.16.1
ENV ISTIO_VERSION=1.4.0
ENV PATH="${HOME}/istio-${ISTIO_VERSION}/bin:${PATH}"
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