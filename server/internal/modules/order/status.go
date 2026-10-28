package order

import (
	"time"

	"jesi-laundry-app-server/internal/model"
	"jesi-laundry-app-server/internal/platform/httpx"
)

var statusRank = map[model.OrderStatus]int{
	model.StatusReceived:   0,
	model.StatusProcessing: 1,
	model.StatusDone:       2,
	model.StatusPickedUp:   3,
}

// stageColumns maps a status rank to the timestamp column that records reaching it.
var stageColumns = [...]string{1: "processing_at", 2: "done_at", 3: "picked_up_at"}

func stageTime(o *model.Order, rank int) *time.Time {
	switch rank {
	case 1:
		return o.ProcessingAt
	case 2:
		return o.DoneAt
	case 3:
		return o.PickedUpAt
	}
	return nil
}

// PlanStatusChange applies the status rules (BACKEND.md §8.4) and returns the columns to update,
// including "status". Forward moves may skip stages; backward moves are owner only and clear the
// timestamps of every stage after the target. It never touches the database.
func PlanStatusChange(o *model.Order, target model.OrderStatus, isOwner bool, now time.Time) (map[string]any, *httpx.AppError) {
	from, to := statusRank[o.Status], statusRank[target]

	switch {
	case to == from:
		return nil, httpx.New(httpx.CodeInvalidStatusTransition, "order already has this status")

	case to < from:
		if !isOwner {
			return nil, httpx.Forbidden("only the owner can move an order back")
		}
		fields := map[string]any{"status": string(target)}
		for rank := to + 1; rank <= 3; rank++ {
			fields[stageColumns[rank]] = nil
		}
		return fields, nil
	}

	if target == model.StatusPickedUp && o.PaymentStatus != model.PaymentPaid {
		return nil, httpx.New(httpx.CodePaymentRequired, "order must be paid before pickup")
	}
	fields := map[string]any{"status": string(target)}
	for rank := from + 1; rank <= to; rank++ {
		if rank == to || stageTime(o, rank) == nil {
			fields[stageColumns[rank]] = now
		}
	}
	return fields, nil
}

// PlanPaymentChange applies the payment rules (BACKEND.md §8.5) and returns the columns to update,
// including "payment_status" and "paid_at".
func PlanPaymentChange(o *model.Order, target model.PaymentStatus, isOwner bool, now time.Time) (map[string]any, *httpx.AppError) {
	if target == o.PaymentStatus {
		return nil, httpx.New(httpx.CodeInvalidStatusTransition, "order already has this payment status")
	}

	if target == model.PaymentPaid {
		return map[string]any{"payment_status": string(target), "paid_at": now}, nil
	}

	if !isOwner {
		return nil, httpx.Forbidden("only the owner can revert a payment")
	}
	if o.Status == model.StatusPickedUp {
		return nil, httpx.New(httpx.CodeOrderNotEditable, "picked up order cannot be marked unpaid")
	}
	return map[string]any{"payment_status": string(target), "paid_at": nil}, nil
}

// CanEdit reports whether the order content may still be edited: not picked up and still unpaid.
func CanEdit(o *model.Order) bool {
	return o.Status != model.StatusPickedUp && o.PaymentStatus == model.PaymentUnpaid
}
