package model

type ServiceCategory string

const (
	CategoryWashIron ServiceCategory = "wash_iron"
	CategoryIronOnly ServiceCategory = "iron_only"
	CategoryWashFold ServiceCategory = "wash_fold"
	CategoryUnit     ServiceCategory = "unit"
)

func (c ServiceCategory) IsValid() bool {
	switch c {
	case CategoryWashIron, CategoryIronOnly, CategoryWashFold, CategoryUnit:
		return true
	}
	return false
}

// IsKilo reports whether the category is one of the three per-kg categories.
func (c ServiceCategory) IsKilo() bool {
	switch c {
	case CategoryWashIron, CategoryIronOnly, CategoryWashFold:
		return true
	}
	return false
}
