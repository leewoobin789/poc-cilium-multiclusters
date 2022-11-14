CLUSTER_NAME = test
CLUSTER_FULL_NAME = kind-${CLUSTER_NAME}
NAMESPACE = demo

PRODUCER-POD-NAME= $(shell kubectl get pods --no-headers -o custom-columns=":metadata.name" | grep "producer-service")

produce-via-app:
	kubectl exec ${PRODUCER-POD-NAME} -- curl localhost:8080/send?number=${NUM}