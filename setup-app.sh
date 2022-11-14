#!/bin/bash

API_SERVICE="api-service"
PRODUCER_SERVICE="producer-service"
CONSUMER_SERVICE="consumer-service"


get_service_dir() {
    # $1: service name
    echo "$(cd apps/$1 && pwd)"
}

delete() {
    # $1: service name
    SERVICE=$1
    DIR=$(get_service_dir "$1")

    kubectl kustomize $DIR/k8s | kubectl delete -f -
}

build() {
    # $1: service name
    SERVICE=$1
    DIR=$(get_service_dir "$1")
    echo "build $SERVICE"
    docker rm -f ${SERVICE}
    docker rmi $(docker images | grep "${SERVICE}") || true
    docker build ${DIR}/. -t ${SERVICE}
    kind load docker-image --name ${ClUSTER_NAME} ${SERVICE}
}

deploy() {
    # $1: service name, $2: bootstrap, $3: topic name 
    echo "deploy customer service"
    DIR=$(get_service_dir "$1")
    gsed -e "s,VALUE_KAFKA_BOOTSTRAP,$2,g" \
        -e "s,VALUE_SCHEMA_REGISTRY_SERVER,$3,g"  \
        -e "s,VALUE_KAFKA_TOPIC,$4,g" \
        $DIR/k8s/deployment.yml.template > $DIR/k8s/deployment.yml
    
    kubectl kustomize $DIR/k8s | kubectl apply -f -
}

delete "$PRODUCER_SERVICE"
build "$PRODUCER_SERVICE"

deploy "$PRODUCER_SERVICE" "$DEP_CLUSTER_NAME-cp-kafka:9092" \
    "http://$DEP_CLUSTER_NAME-cp-schema-registry:8081" "$INCOMING_TOPIC"