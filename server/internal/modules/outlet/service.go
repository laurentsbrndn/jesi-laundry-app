package outlet

import (
	"context"
	"errors"
	"fmt"
	"strings"

	"github.com/google/uuid"
	"gorm.io/gorm"

	"jesi-laundry-app-server/internal/model"
	"jesi-laundry-app-server/internal/platform/database"
	"jesi-laundry-app-server/internal/platform/httpx"
	"jesi-laundry-app-server/internal/platform/middleware"
)

// DefaultServiceCreator is the part of the catalog module needed to seed a new outlet.
type DefaultServiceCreator interface {
	CreateDefaults(ctx context.Context, outletID uuid.UUID) error
}

type Service struct {
	db        *gorm.DB
	repo      *Repository
	catalogTx func(tx *gorm.DB) DefaultServiceCreator
}

func NewService(db *gorm.DB, repo *Repository, catalogTx func(tx *gorm.DB) DefaultServiceCreator) *Service {
	return &Service{db: db, repo: repo, catalogTx: catalogTx}
}

// List returns every outlet for the owner, and only the caller's own outlet for staff.
func (s *Service) List(ctx context.Context, p middleware.Principal) ([]model.Outlet, error) {
	outlets, err := s.repo.List(ctx, middleware.ScopedOutletID(p, nil))
	if err != nil {
		return nil, fmt.Errorf("list outlets: %w", err)
	}
	return outlets, nil
}

// Create inserts the outlet and its default catalog in one transaction.
func (s *Service) Create(ctx context.Context, req CreateOutletRequest) (*model.Outlet, error) {
	name := strings.TrimSpace(req.Name)
	if name == "" {
		return nil, httpx.FieldViolation("name", "required")
	}

	o := &model.Outlet{
		Code:     strings.ToUpper(strings.TrimSpace(req.Code)),
		Name:     name,
		Address:  nilIfEmpty(req.Address),
		Phone:    nilIfEmpty(req.Phone),
		IsActive: true,
	}
	err := database.WithTx(ctx, s.db, func(tx *gorm.DB) error {
		if err := s.repo.WithTx(tx).Create(ctx, o); err != nil {
			return err
		}
		return s.catalogTx(tx).CreateDefaults(ctx, o.ID)
	})
	if err != nil {
		if constraint, ok := database.UniqueViolation(err); ok && constraint == "uq_outlets_code" {
			return nil, httpx.New(httpx.CodeOutletCodeTaken, "outlet code already in use")
		}
		return nil, fmt.Errorf("create outlet: %w", err)
	}
	return o, nil
}

// Update changes only the fields that were sent. The code never changes.
func (s *Service) Update(ctx context.Context, id uuid.UUID, req UpdateOutletRequest) (*model.Outlet, error) {
	fields := map[string]any{}
	if req.Name != nil {
		name := strings.TrimSpace(*req.Name)
		if name == "" {
			return nil, httpx.FieldViolation("name", "required")
		}
		fields["name"] = name
	}
	if req.Address != nil {
		fields["address"] = nilIfEmpty(*req.Address)
	}
	if req.Phone != nil {
		fields["phone"] = nilIfEmpty(*req.Phone)
	}
	if req.IsActive != nil {
		fields["is_active"] = *req.IsActive
	}

	if _, err := s.find(ctx, id); err != nil {
		return nil, err
	}
	if len(fields) > 0 {
		if err := s.repo.Update(ctx, id, fields); err != nil {
			return nil, fmt.Errorf("update outlet: %w", err)
		}
	}
	return s.find(ctx, id)
}

func (s *Service) find(ctx context.Context, id uuid.UUID) (*model.Outlet, error) {
	o, err := s.repo.FindByID(ctx, id)
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, httpx.NotFound("outlet not found")
	}
	if err != nil {
		return nil, fmt.Errorf("find outlet: %w", err)
	}
	return o, nil
}

func nilIfEmpty(s string) *string {
	s = strings.TrimSpace(s)
	if s == "" {
		return nil
	}
	return &s
}
