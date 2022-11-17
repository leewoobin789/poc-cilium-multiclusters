#!/bin/bash

DEP=${1}

add_chart() {
    NAME="${1}"
    URL="${2}"

    echo "Check existence of $NAME helm repo"
    REPO_EXISTENCE=$(helm repo list | grep "$URL")

    if [ -z "${REPO_EXISTENCE}" ]; then 
        echo "$NAME helm chart repo is being added"
        helm repo add $NAME $URL
    fi
}

##### Cilium SETUP
setup_cilium() {
    CLUSTER_NAME="${1}"
    CLUSTER_ID="${2}"
    IS_FIRST="${3:-true}"
    INHERITED_CONTEXT="${4}"

    if [ "$IS_FIRST" = true ]; then
        cilium install --context kind-${CLUSTER_NAME} \
            --cluster-id ${CLUSTER_ID} \
            --cluster-name ${CLUSTER_NAME}
    else
        cilium install --context kind-${CLUSTER_NAME} \
            --cluster-id ${CLUSTER_ID} \
            --cluster-name ${CLUSTER_NAME} \
            --inherit-ca ${INHERITED_CONTEXT}
    fi

    cilium hubble enable
}

##### Linkerd SETUP
#TODO:

##### Opentelemetry SETUP
setup_otel() {
    # Cert-manager as prerequisite
    kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.10.0/cert-manager.yaml
    kubectl wait deployment -n cert-manager cert-manager --for condition=Available=True --timeout=-1s
    kubectl wait deployment -n cert-manager cert-manager-cainjector --for condition=Available=True --timeout=-1s
    kubectl wait deployment -n cert-manager cert-manager-webhook --for condition=Available=True --timeout=-1s

    # Opentelemetry operator
    kubectl apply -f https://github.com/open-telemetry/opentelemetry-operator/releases/latest/download/opentelemetry-operator.yaml
    kubectl wait deployment -n  opentelemetry-operator-system opentelemetry-operator-controller-manager --for condition=Available=True --timeout=-1s
    
    for CONFIG in "$@"
    do  
        echo "start deploying otel collector ${CONFIG}"
        kubectl apply -f ${CONFIG}
    done
}


##### Kafka SETUP
# (1) cluster name of kafka, (2) name of topic to be created
setup_kafka_cluster() {
    CLUSTER_NAME="${1}"
    TOPIC="${2}"
    if [ -z "${CLUSTER_NAME}" ]; then 
        echo "first paramete of setup_kafka_cluster not added"
        exit 1
    fi
    if [ -z "${TOPIC}" ]; then
        echo "second paramete of setup_kafka_cluster not added"
        exit 1
    fi

    add_chart "confluentinc" "https://confluentinc.github.io/cp-helm-charts"

    echo "Kafka cluster is being deployed"
    helm install -f ../config/confluent-value.yaml \
        --namespace ${CLUSTER_NAME}-ns \
        $CLUSTER_NAME confluentinc/cp-helm-charts || true
    # wait for kafka
    echo "Waiting for kafka cluster to be deployed successfully"
    sleep 5 # wait for a while til the deployments & statefulsets become recognizable
    kubectl wait --for=condition=available --timeout=-1s deployment/$CLUSTER_NAME-cp-control-center # to prevent topic to be generated before consumer deployed
    declare -a num=("0" "1" "2")
    for i in "${num[@]}"
    do
        kubectl wait --for=condition=ready --timeout=-1s pod/$CLUSTER_NAME-cp-kafka-${i}
        kubectl wait --for=condition=ready --timeout=-1s pod/$CLUSTER_NAME-cp-zookeeper-${i}
    done
    # create topic
    sleep 10
    TOPIC=$1
    echo "Topic($TOPIC) is being created"
    kubectl exec -c cp-kafka-broker -it $CLUSTER_NAME-cp-kafka-0 -- /bin/bash /usr/bin/kafka-topics --create --zookeeper $CLUSTER_NAME-cp-zookeeper:2181 --topic $TOPIC --partitions 3 --replication-factor 1
    sleep 2
    echo "setup_kafka_cluster finished"
}

echo "start installing dep $DEP"

if [ "${DEP}" = "cilium" ]; then
    setup_cilium "$2" "$3" "$4" "$5"
fi

if [ "${DEP}" = "kafka" ]; then
    setup_kafka_cluster "$2" "$3"
fi

if [ "${DEP}" = "otel" ]; then
    setup_otel "$2"
fi