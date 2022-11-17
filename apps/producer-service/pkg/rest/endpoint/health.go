package endpoint

import (
	"net/http"

	"github.com/leewoobin789/poc-cilium-multiclusters/producer-service/pkg/rest"
)

type healthEndpoint struct {
	info rest.HandlerInfo
}

func newhealthEndpoint() rest.Handler {
	return healthEndpoint{
		info: rest.HandlerInfo{
			Path:   "/health",
			Method: rest.GET,
		},
	}
}

func (e healthEndpoint) GetInfo() rest.HandlerInfo {
	return e.info
}

func (e healthEndpoint) Run(w http.ResponseWriter, r *http.Request) {
	rest.RespondWithJSON(w, "healthy")
}
