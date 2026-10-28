package model

type PaymentStatus string

const (
	PaymentUnpaid PaymentStatus = "unpaid"
	PaymentPaid   PaymentStatus = "paid"
)

func (s PaymentStatus) IsValid() bool {
	return s == PaymentUnpaid || s == PaymentPaid
}
