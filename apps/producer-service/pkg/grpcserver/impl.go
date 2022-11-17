package grpcserver

import (
	context "context"

	"github.com/leewoobin789/poc-cilium-multiclusters/producer-service/pkg/producer"
)

func pointer[T any](val T) *T {
	return &val
}

func NewOrderGrpcServer(kafkaBootstrap string, schemaRegistryUrl string) server {
	return server{
		producer: producer.NewCustomKafkaProducer(kafkaBootstrap, schemaRegistryUrl),
	}
}

type server struct {
	UnimplementedOrderServer
	producer producer.CustomProducer
}

// SayHello implements helloworld.GreeterServer
func (s *server) Create(context.Context, *OrderCreationRequest) (*OrderCreatinoResponse, error) {
	//TODO: impl
	return &OrderCreatinoResponse{
		Status:   OrderCreatinoResponseStatus_SUCCESFULL,
		ErrorMsg: pointer("hallo"),
	}, nil
}
