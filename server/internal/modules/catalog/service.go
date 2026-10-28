package catalog

import (
	"context"
	"errors"
	"fmt"
	"strings"

	"github.com/google/uuid"
	"github.com/shopspring/decimal"
	"gorm.io/gorm"

	"jesi-laundry-app-server/internal/model"
	"jesi-laundry-app-server/internal/platform/httpx"
	"jesi-laundry-app-server/internal/platform/middleware"
)

const (
	sortOrderStep = 10
	maxMinQty     = 1_000_000
)

// OutletReader is the part of the outlet module the catalog needs.
type OutletReader interface {
	FindByID(ctx context.Context, id uuid.UUID) (*model.Outlet, error)
	List(ctx context.Context, onlyID *uuid.UUID) ([]model.Outlet, error)
}

type Service struct {
	repo    *Repository
	outlets OutletReader
}

func NewService(repo *Repository, outlets OutletReader) *Service {
	return &Service{repo: repo, outlets: outlets}
}

// List returns services of one outlet. Staff are pinned to their own outlet and see active services only.
// An owner must name the outlet when more than one exists.
func (s *Service) List(ctx context.Context, p middleware.Principal, requested *uuid.UUID, includeInactive bool) ([]model.LaundryService, error) {
	if !p.IsOwner() {
		includeInactive = false
	}

	outletID := middleware.ScopedOutletID(p, requested)
	if outletID == nil {
		outlets, err := s.outlets.List(ctx, nil)
		if err != nil {
			return nil, fmt.Errorf("list outlets: %w", err)
		}
		switch len(outlets) {
		case 0:
			return []model.LaundryService{}, nil
		case 1:
			id := outlets[0].ID
			outletID = &id
		default:
			return nil, httpx.FieldViolation("outlet_id", "required")
		}
	} else if p.IsOwner() {
		if _, err := s.findOutlet(ctx, *outletID); err != nil {
			return nil, err
		}
	}

	services, err := s.repo.List(ctx, *outletID, includeInactive)
	if err != nil {
		return nil, fmt.Errorf("list services: %w", err)
	}
	return services, nil
}

func (s *Service) Create(ctx context.Context, req CreateServiceRequest) (*model.LaundryService, error) {
	outletID, err := uuid.Parse(req.OutletID)
	if err != nil {
		return nil, httpx.FieldViolation("outlet_id", "uuid")
	}
	name := strings.TrimSpace(req.Name)
	if name == "" {
		return nil, httpx.FieldViolation("name", "required")
	}
	if _, err := s.findOutlet(ctx, outletID); err != nil {
		return nil, err
	}

	minQty := decimal.Zero
	if req.MinQuantity != nil {
		if err := checkMinQuantity(*req.MinQuantity); err != nil {
			return nil, err
		}
		minQty = *req.MinQuantity
	}
	if err := s.ensureNameFree(ctx, outletID, name, nil); err != nil {
		return nil, err
	}

	sortOrder := 0
	if req.SortOrder != nil {
		sortOrder = *req.SortOrder
	} else {
		top, err := s.repo.MaxSortOrder(ctx, outletID)
		if err != nil {
			return nil, fmt.Errorf("max sort order: %w", err)
		}
		sortOrder = top + sortOrderStep
	}

	svc := &model.LaundryService{
		OutletID:            outletID,
		Category:            model.CategoryUnit,
		Name:                name,
		PricingUnit:         model.PricingUnit(req.PricingUnit),
		RegularPrice:        *req.RegularPrice,
		ExpressPrice:        *req.ExpressPrice,
		RegularDurationDays: req.RegularDurationDays,
		ExpressDurationDays: req.ExpressDurationDays,
		MinQuantity:         minQty,
		IsSystem:            false,
		IsActive:            true,
		SortOrder:           sortOrder,
	}
	if err := s.repo.Create(ctx, svc); err != nil {
		return nil, fmt.Errorf("create service: %w", err)
	}
	return svc, nil
}

func (s *Service) Update(ctx context.Context, id uuid.UUID, req UpdateServiceRequest) (*model.LaundryService, error) {
	svc, err := s.find(ctx, id)
	if err != nil {
		return nil, err
	}

	if req.Category != nil && model.ServiceCategory(*req.Category) != svc.Category {
		return nil, httpx.FieldViolation("category", "immutable")
	}
	if req.PricingUnit != nil && model.PricingUnit(*req.PricingUnit) != svc.PricingUnit {
		return nil, httpx.FieldViolation("pricing_unit", "immutable")
	}

	fields := map[string]any{}
	if req.Name != nil {
		name := strings.TrimSpace(*req.Name)
		if name == "" {
			return nil, httpx.FieldViolation("name", "required")
		}
		if err := s.ensureNameFree(ctx, svc.OutletID, name, &svc.ID); err != nil {
			return nil, err
		}
		fields["name"] = name
	}
	if req.RegularPrice != nil {
		fields["regular_price"] = *req.RegularPrice
	}
	if req.ExpressPrice != nil {
		fields["express_price"] = *req.ExpressPrice
	}
	if req.RegularDurationDays != nil {
		fields["regular_duration_days"] = *req.RegularDurationDays
	}
	if req.ExpressDurationDays != nil {
		fields["express_duration_days"] = *req.ExpressDurationDays
	}
	if req.MinQuantity != nil {
		if err := checkMinQuantity(*req.MinQuantity); err != nil {
			return nil, err
		}
		fields["min_quantity"] = *req.MinQuantity
	}
	if req.IsActive != nil {
		fields["is_active"] = *req.IsActive
	}
	if req.SortOrder != nil {
		fields["sort_order"] = *req.SortOrder
	}

	if len(fields) > 0 {
		if err := s.repo.Update(ctx, id, fields); err != nil {
			return nil, fmt.Errorf("update service: %w", err)
		}
	}
	return s.find(ctx, id)
}

// Delete soft-deletes a unit service. The built-in kilo services cannot be deleted.
func (s *Service) Delete(ctx context.Context, id uuid.UUID) error {
	svc, err := s.find(ctx, id)
	if err != nil {
		return err
	}
	if svc.IsSystem {
		return httpx.New(httpx.CodeSystemServiceNotDeletable, "built-in service cannot be deleted")
	}
	if err := s.repo.SoftDelete(ctx, id); err != nil {
		return fmt.Errorf("delete service: %w", err)
	}
	return nil
}

func (s *Service) find(ctx context.Context, id uuid.UUID) (*model.LaundryService, error) {
	svc, err := s.repo.FindByID(ctx, id)
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, httpx.NotFound("service not found")
	}
	if err != nil {
		return nil, fmt.Errorf("find service: %w", err)
	}
	return svc, nil
}

func (s *Service) findOutlet(ctx context.Context, id uuid.UUID) (*model.Outlet, error) {
	o, err := s.outlets.FindByID(ctx, id)
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, httpx.NotFound("outlet not found")
	}
	if err != nil {
		return nil, fmt.Errorf("find outlet: %w", err)
	}
	return o, nil
}

func (s *Service) ensureNameFree(ctx context.Context, outletID uuid.UUID, name string, excludeID *uuid.UUID) error {
	taken, err := s.repo.NameExists(ctx, outletID, name, excludeID)
	if err != nil {
		return fmt.Errorf("check service name: %w", err)
	}
	if taken {
		return httpx.New(httpx.CodeServiceNameTaken, "service name already used in this outlet")
	}
	return nil
}

func checkMinQuantity(q decimal.Decimal) error {
	switch {
	case q.IsNegative():
		return httpx.FieldViolation("min_quantity", "gte")
	case q.GreaterThan(decimal.NewFromInt(maxMinQty)):
		return httpx.FieldViolation("min_quantity", "lte")
	case !q.Equal(q.Round(2)):
		return httpx.FieldViolation("min_quantity", "max_2_decimals")
	}
	return nil
}
