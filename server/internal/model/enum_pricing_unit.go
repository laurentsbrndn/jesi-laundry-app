package model

type PricingUnit string

const (
	PricingUnitKg    PricingUnit = "kg"
	PricingUnitPiece PricingUnit = "piece"
	PricingUnitSqm   PricingUnit = "sqm"
)

func (u PricingUnit) IsValid() bool {
	switch u {
	case PricingUnitKg, PricingUnitPiece, PricingUnitSqm:
		return true
	}
	return false
}
