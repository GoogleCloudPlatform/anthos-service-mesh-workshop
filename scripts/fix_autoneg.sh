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

export SCRIPT_DIR=$(dirname $(readlink -f $0 2>/dev/null) 2>/dev/null || echo "${PWD}/$(dirname $0)")

export VARS_FILE=${SCRIPT_DIR}/../vars/vars.sh

source ${VARS_FILE}

kubectl --context ${OPS_GKE_1} -n istio-system annotate svc istio-ingressgateway anthos.cft.dev/autoneg-status-
kubectl --context ${OPS_GKE_2} -n istio-system annotate svc istio-ingressgateway anthos.cft.dev/autoneg-status-