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

# Set certs dir
# PWD=`pwd`
# PARENT=`dirname ${PWD}`
# CERTS_DIR=${PARENT}/certs
CERTS_DIR=./istiocerts

# Make folder if doesn't exist
mkdir -p ${CERTS_DIR}

# Create a private key for the root ca
openssl genrsa -out ${CERTS_DIR}/root-ca-key.pem 4096

# Create a root CA cert (typically root CA certs are long living for example 10 years)
openssl req -new -x509 -days 3650 -key ${CERTS_DIR}/root-ca-key.pem -out ${CERTS_DIR}/root-cert.pem -subj "/C=US/ST=California/L=SanFrancisco/O=IstioPlayground Ltd./OU=IT/CN=rootca.platformx.dev"

# Create an intermediate CA (Citadel CA) private key
openssl genrsa -out ${CERTS_DIR}/ca-key.pem 4096

# Create a signing request (CSR) for the Citadel CA
openssl req -new -key ${CERTS_DIR}/ca-key.pem -out ${CERTS_DIR}/citadel-ca.csr -subj "/C=US/ST=California/L=SanFrancisco/O=IstioPlayground Ltd./OU=IT/CN=istioca.platformx.dev"

# Create a custom ssl config - make sure Citadel CA can sign other certs (workload certs)
cat > ${CERTS_DIR}/ca.cfg <<EOF
[ citadel_ca ]
basicConstraints = CA:TRUE
keyUsage = keyCertSign
subjectAltName = @alt_names
[ alt_names ]
DNS.1 = ca.istio.io
EOF

# Generate a Citadel cert from the CSR generated earlier
openssl x509 -req -days 1000 -in ${CERTS_DIR}/citadel-ca.csr -extfile ${CERTS_DIR}/ca.cfg -extensions citadel_ca -CA ${CERTS_DIR}/root-cert.pem -CAkey ${CERTS_DIR}/root-ca-key.pem -CAcreateserial  -out ${CERTS_DIR}/ca-cert.pem

# Copy ca-cert as cert-chain
cp ${CERTS_DIR}/ca-cert.pem ${CERTS_DIR}/cert-chain.pem
