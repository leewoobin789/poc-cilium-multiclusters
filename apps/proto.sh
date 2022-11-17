protoc --go_out=./producer-service/pkg --go_opt=module=github.com/leewoobin789/poc-cilium-multiclusters/producer-service \
    --go-grpc_out=./producer-service/pkg --go-grpc_opt=module=github.com/leewoobin789/poc-cilium-multiclusters/producer-service \
    protobufs/order.proto