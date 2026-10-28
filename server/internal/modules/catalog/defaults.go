package catalog

import (
	"github.com/google/uuid"
	"github.com/shopspring/decimal"

	"jesi-laundry-app-server/internal/model"
)

// defaultServices builds the starter catalog for a new outlet (BACKEND.md §7.2).
// Prices marked as placeholders are expected to be changed by the owner.
func defaultServices(outletID uuid.UUID) []model.LaundryService {
	kilo := func(category model.ServiceCategory, name string, regular, express int64, sort int) model.LaundryService {
		return model.LaundryService{
			OutletID:            outletID,
			Category:            category,
			Name:                name,
			PricingUnit:         model.PricingUnitKg,
			RegularPrice:        regular,
			ExpressPrice:        express,
			RegularDurationDays: 3,
			ExpressDurationDays: 1,
			MinQuantity:         decimal.NewFromInt(3),
			IsSystem:            true,
			IsActive:            true,
			SortOrder:           sort,
		}
	}
	unit := func(name string, pricing model.PricingUnit, regular, express int64, sort int) model.LaundryService {
		return model.LaundryService{
			OutletID:            outletID,
			Category:            model.CategoryUnit,
			Name:                name,
			PricingUnit:         pricing,
			RegularPrice:        regular,
			ExpressPrice:        express,
			RegularDurationDays: 3,
			ExpressDurationDays: 1,
			MinQuantity:         decimal.Zero,
			IsActive:            true,
			SortOrder:           sort,
		}
	}

	return []model.LaundryService{
		kilo(model.CategoryWashIron, "Cuci Setrika", 7000, 12000, 10),
		kilo(model.CategoryIronOnly, "Setrika", 5000, 8000, 20),
		kilo(model.CategoryWashFold, "Cuci Lipat", 5000, 8000, 30),
		unit("Bed Cover", model.PricingUnitPiece, 25000, 35000, 40),
		unit("Boneka", model.PricingUnitPiece, 15000, 25000, 50),
		unit("Karpet", model.PricingUnitSqm, 15000, 25000, 60),
	}
}
