package endpoint

import (
	"fmt"
	"os"

	"github.com/leewoobin789/poc-cilium-multiclusters/producer-service/pkg/producer"
	"github.com/leewoobin789/poc-cilium-multiclusters/producer-service/pkg/rest"
)

func ReturnBundle() []rest.Handler {
	kafkaServer := os.Getenv("KAFKA_SERVER")
	schemaRegistryUrl := os.Getenv("SCHEMA_REGISTRY_SERVER")
	fmt.Println(kafkaServer, schemaRegistryUrl)
	customProducer := producer.NewCustomKafkaProducer(kafkaServer, schemaRegistryUrl)
	return []rest.Handler{
		newSendEndpoint(customProducer),
		newhealthEndpoint(),
	}
}
