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
}

##### Linkerd SETUP
#TODO:

##### Opentelemetry SETUP
#TODO:

##### Kafka SETUP
# (1) cluster name of kafka, (2) name of topic to be created
setup_kafka_cluster() {
    DEP_CLUSTER_NAME="${1}"
    TOPIC="${2}"
    if [ -z "${DEP_CLUSTER_NAME}" ]; then 
        echo "first paramete of setup_kafka_cluster not added"
        exit 1
    fi
    if [ -z "${TOPIC}" ]; then
        echo "second paramete of setup_kafka_cluster not added"
        exit 1
    fi

    add_chart "confluentinc" "https://confluentinc.github.io/cp-helm-charts"

    echo "Kafka cluster is being deployed"
    helm install -f ./config/confluent-value.yaml \
        $DEP_CLUSTER_NAME confluentinc/cp-helm-charts || true
    # wait for kafka
    echo "Waiting for kafka cluster to be deployed successfully"
    kubectl wait --for=condition=available --timeout=-1s deployment/$DEP_CLUSTER_NAME-cp-control-center # to prevent topic to be generated before consumer deployed
    declare -a num=("0" "1" "2")
    for i in "${num[@]}"
    do
        kubectl wait --for=condition=ready --timeout=-1s pod/$DEP_CLUSTER_NAME-cp-kafka-${i}
        kubectl wait --for=condition=ready --timeout=-1s pod/$DEP_CLUSTER_NAME-cp-zookeeper-${i}
    done
    # create topic
    sleep 10
    TOPIC=$1
    echo "Topic($TOPIC) is being created"
    kubectl exec -c cp-kafka-broker -it $DEP_CLUSTER_NAME-cp-kafka-0 -- /bin/bash /usr/bin/kafka-topics --create --zookeeper $DEP_CLUSTER_NAME-cp-zookeeper:2181 --topic $TOPIC --partitions 3 --replication-factor 1
    sleep 2
    echo "setup_kafka_cluster finished"
}

echo "start installing dep $DEP"

if [ "${DEP}" = "cilium" ]; then
    setup_cilium "$2" "$3" "$4" "$5"
fi