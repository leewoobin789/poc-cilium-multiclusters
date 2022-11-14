#!/bin/bash

kind_delete() {
    CLUSTER_NAME="${1}"

    kind delete cluster --name kind-${CLUSTER_NAME}
}

kind-setup() {
    CLUSTER_NAME="${1}"

    kind create cluster --config=./config/kind-config.yaml
	kubectl config use-context kind-${CLUSTER_NAME}
	kubectl create secret docker-registry regcred --docker-username=RANDOM --docker-password=RANDOM --docker-email=RANDOM
}