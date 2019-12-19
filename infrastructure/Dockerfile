FROM gcr.io/google.com/cloudsdktool/cloud-sdk:alpine
RUN apk add -u jq python3 openssl

ENV TERRAFORM_VERSION=0.12.13
ENV KUBECTL_VERSION=1.16.1
ENV ISTIO_VERSION=1.4.0
ENV PATH="${HOME}/istio-${ISTIO_VERSION}/bin:${PATH}"

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
# Install istio
RUN wget https://github.com/istio/istio/releases/download/${ISTIO_VERSION}/istio-${ISTIO_VERSION}-linux.tar.gz && \
    tar zxfv istio-${ISTIO_VERSION}-linux.tar.gz && \
    cp istio-${ISTIO_VERSION}/bin/istioctl /usr/local/bin && \
    rm -r istio-${ISTIO_VERSION}-linux.tar.gz
