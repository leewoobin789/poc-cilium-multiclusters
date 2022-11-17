package endpoint

import (
	"net/http"
	"os"
	"strconv"
	"time"

	"github.com/google/uuid"
	"github.com/leewoobin789/poc-cilium-multiclusters/producer-service/pkg/avroschema"
	"github.com/leewoobin789/poc-cilium-multiclusters/producer-service/pkg/producer"
	"github.com/leewoobin789/poc-cilium-multiclusters/producer-service/pkg/rest"
)

var TOPIC = os.Getenv("KAFKA_TOPIC")

type sendEndpoint struct {
	info     rest.HandlerInfo
	producer producer.CustomProducer
}

func newSendEndpoint(producer producer.CustomProducer) rest.Handler {
	return sendEndpoint{
		info: rest.HandlerInfo{
			Path:   "/send",
			Method: rest.GET,
		},
		producer: producer,
	}
}

func (e sendEndpoint) GetInfo() rest.HandlerInfo {
	return e.info
}

func (e sendEndpoint) Run(w http.ResponseWriter, r *http.Request) {
	Response := struct {
		Message string `json:"message"`
	}{
		Message: "successful",
	}

	strNum := r.URL.Query().Get("number")
	if len(strNum) == 0 {
		strNum = "1"
	}
	num, err := strconv.Atoi(strNum)
	if err != nil {
		Response.Message = err.Error()
		rest.RespondwithJSON(w, http.StatusNotAcceptable, Response)
	}

	keyProductID := uuid.NewString()
	value := &avroschema.OrderCreated{
		Name:       "Woobin",
		FamilyName: "Lee",
		Birth:      0, // TODO:
		CustomId:   "mycustomid-1234",
		UnitPrice:  12.95,
		Amount:     5,
		Credit:     10,
		Distance:   10,
	}

	for i := 0; i <= num; i++ {
		time.Sleep(time.Millisecond * 100)
		if err := e.producer.Send(TOPIC, keyProductID, value); err != nil {
			Response.Message = err.Error()
			break
		}
	}

	rest.RespondWithJSON(w, Response)
}
