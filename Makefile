TOPIC ?= order_created

delete-kind:
	kind delete cluster --name ${CLUSTER_NAME}

setup-kind:
	kind create cluster --config=./config/kind-${CLUSTER_NAME}.yaml --name ${CLUSTER_NAME}
	kubectl config use-context kind-${CLUSTER_NAME}
	kubectl create secret docker-registry regcred --docker-username=RANDOM --docker-password=RANDOM --docker-email=RANDOM
	kubectl create namespace ${CLUSTER_NAME}-ns

cluster-%:
	$(MAKE) delete-kind CLUSTER_NAME=$*
	$(MAKE) setup-kind CLUSTER_NAME=$*
	$(MAKE) dep-$*

dep-coreservice:
	cd scripts && bash ./dep.sh "cilium" "coreservice" "1" "true"
	cd scripts && bash ./dep.sh "kafka" "coreservice" "${TOPIC}"
	cd scripts && bash ./dep.sh "otel" "../config/hubble-otel.yaml"

dep-apifactory:
	cd scripts && bash ./dep.sh "cilium" "coreservice" "2" "false" "kind-coreservice"
	cd scripts && bash ./dep.sh "otel" "../config/hubble-otel.yaml"

dep-obs:
	cd scripts && bash ./dep.sh "cilium" "coreservice" "3" "false" "kind-coreservice"
	cd scripts && bash ./dep.sh "otel" "../config/hubble-otel.yaml"

clusters-setup: cluster-coreservice # cluster-apifactory cluster-obs