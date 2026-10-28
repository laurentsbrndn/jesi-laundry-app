package model

type OrderStatus string

const (
	StatusReceived   OrderStatus = "received"
	StatusProcessing OrderStatus = "processing"
	StatusDone       OrderStatus = "done"
	StatusPickedUp   OrderStatus = "picked_up"
)

func (s OrderStatus) IsValid() bool {
	switch s {
	case StatusReceived, StatusProcessing, StatusDone, StatusPickedUp:
		return true
	}
	return false
}
