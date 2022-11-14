#!/bin/bash
. common.sh

##### Initial Validation
initial() {
    helm repo update
}

##### Cilium SETUP
#TODO:
setup_cilium() {
    add_chart "cilium" "https://helm.cilium.io/"

    helm install cilium cilium/cilium --version 1.12.3 \
        --namespace kube-system
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
    if [ -z "${DEP_CLUSTER_NAME}" ] {
        echo "first paramete of setup_kafka_cluster not added"
        exit 1
    }
    if [ -z "${TOPIC}" ] {
        echo "second paramete of setup_kafka_cluster not added"
        exit 1
    }

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

