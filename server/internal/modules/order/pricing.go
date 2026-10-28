package order

import (
	"time"

	"github.com/shopspring/decimal"

	"jesi-laundry-app-server/internal/model"
	"jesi-laundry-app-server/internal/platform/httpx"
)

const (
	minItems = 1
	maxItems = 50
)

var (
	maxKg     = decimal.RequireFromString("999.99")
	maxPieces = decimal.NewFromInt(999)
	maxDim    = decimal.RequireFromString("99.99")
)

// ItemInput is the raw quantity input of one order item; which fields matter depends on the pricing unit.
type ItemInput struct {
	Quantity *decimal.Decimal
	LengthM  *decimal.Decimal
	WidthM   *decimal.Decimal
}

// ItemResult is the server-computed outcome for one item, ready to be snapshotted into an order_item.
type ItemResult struct {
	Quantity       decimal.Decimal
	LengthM        decimal.NullDecimal
	WidthM         decimal.NullDecimal
	BilledQuantity decimal.Decimal
	UnitPrice      int64
	Subtotal       int64
	DurationDays   int16
}

// CheckItemCount enforces 1–50 items per order.
func CheckItemCount(n int) *httpx.FieldError {
	switch {
	case n < minItems:
		return &httpx.FieldError{Field: "items", Rule: "min"}
	case n > maxItems:
		return &httpx.FieldError{Field: "items", Rule: "max"}
	}
	return nil
}

// CalculateItem validates the input for the service's pricing unit and computes billed quantity,
// unit price, subtotal and duration. The returned FieldError names the offending field relative to the item.
func CalculateItem(svc *model.LaundryService, speed model.ServiceSpeed, in ItemInput) (ItemResult, *httpx.FieldError) {
	var res ItemResult

	switch svc.PricingUnit {
	case model.PricingUnitKg:
		q, ferr := requirePositive("quantity", in.Quantity, maxKg)
		if ferr != nil {
			return res, ferr
		}
		res.Quantity = q

	case model.PricingUnitPiece:
		if in.Quantity == nil {
			return res, &httpx.FieldError{Field: "quantity", Rule: "required"}
		}
		q := *in.Quantity
		switch {
		case !q.IsInteger():
			return res, &httpx.FieldError{Field: "quantity", Rule: "integer"}
		case q.LessThan(decimal.NewFromInt(1)):
			return res, &httpx.FieldError{Field: "quantity", Rule: "gte"}
		case q.GreaterThan(maxPieces):
			return res, &httpx.FieldError{Field: "quantity", Rule: "lte"}
		}
		res.Quantity = q

	case model.PricingUnitSqm:
		length, ferr := requirePositive("length_m", in.LengthM, maxDim)
		if ferr != nil {
			return res, ferr
		}
		width, ferr := requirePositive("width_m", in.WidthM, maxDim)
		if ferr != nil {
			return res, ferr
		}
		area := length.Mul(width).Round(2)
		if !area.IsPositive() {
			return res, &httpx.FieldError{Field: "length_m", Rule: "area_too_small"}
		}
		res.Quantity = area
		res.LengthM = decimal.NewNullDecimal(length)
		res.WidthM = decimal.NewNullDecimal(width)

	default:
		return res, &httpx.FieldError{Field: "service_id", Rule: "pricing_unit"}
	}

	res.BilledQuantity = decimal.Max(res.Quantity, svc.MinQuantity)
	if speed == model.SpeedExpress {
		res.UnitPrice = svc.ExpressPrice
		res.DurationDays = svc.ExpressDurationDays
	} else {
		res.UnitPrice = svc.RegularPrice
		res.DurationDays = svc.RegularDurationDays
	}
	res.Subtotal = res.BilledQuantity.Mul(decimal.NewFromInt(res.UnitPrice)).Round(0).IntPart() // half-up to whole Rupiah
	return res, nil
}

// TotalAmount sums the item subtotals.
func TotalAmount(items []ItemResult) int64 {
	var total int64
	for _, it := range items {
		total += it.Subtotal
	}
	return total
}

// EstimatedDoneAt is createdAt plus the longest item duration, in 24-hour days.
func EstimatedDoneAt(createdAt time.Time, items []ItemResult) time.Time {
	var days int16
	for _, it := range items {
		if it.DurationDays > days {
			days = it.DurationDays
		}
	}
	return createdAt.Add(time.Duration(days) * 24 * time.Hour)
}

// requirePositive checks 0 < v <= max with at most 2 decimals.
func requirePositive(field string, v *decimal.Decimal, limit decimal.Decimal) (decimal.Decimal, *httpx.FieldError) {
	if v == nil {
		return decimal.Zero, &httpx.FieldError{Field: field, Rule: "required"}
	}
	d := *v
	switch {
	case !d.IsPositive():
		return decimal.Zero, &httpx.FieldError{Field: field, Rule: "gt"}
	case d.GreaterThan(limit):
		return decimal.Zero, &httpx.FieldError{Field: field, Rule: "lte"}
	case !d.Equal(d.Round(2)):
		return decimal.Zero, &httpx.FieldError{Field: field, Rule: "max_2_decimals"}
	}
	return d, nil
}
