package customer

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"

	"jesi-laundry-app-server/internal/model"
	"jesi-laundry-app-server/internal/platform/httpx"
)

const (
	defaultLimit = 10
	maxLimit     = 100
)

type Service struct {
	repo *Repository
}

func NewService(repo *Repository) *Service {
	return &Service{repo: repo}
}

// WithTx returns a service bound to tx so the order module can resolve customers inside its transaction.
func (s *Service) WithTx(tx *gorm.DB) *Service {
	return &Service{repo: s.repo.WithTx(tx)}
}

func (s *Service) List(ctx context.Context, search string, page httpx.Page) ([]model.Customer, httpx.Meta, error) {
	page = page.Normalize(defaultLimit, maxLimit)
	search = strings.TrimSpace(search)

	customers, total, err := s.repo.List(ctx, ListFilter{
		Search:      search,
		PhoneDigits: searchDigits(search),
		Offset:      page.Offset(),
		Limit:       page.Limit,
	})
	if err != nil {
		return nil, httpx.Meta{}, fmt.Errorf("list customers: %w", err)
	}
	return customers, page.Meta(total), nil
}

func (s *Service) Get(ctx context.Context, id uuid.UUID) (*model.Customer, error) {
	c, err := s.repo.FindByID(ctx, id)
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, httpx.NotFound("customer not found")
	}
	if err != nil {
		return nil, fmt.Errorf("find customer: %w", err)
	}
	return c, nil
}

func (s *Service) Update(ctx context.Context, id uuid.UUID, req UpdateCustomerRequest) (*model.Customer, error) {
	if _, err := s.Get(ctx, id); err != nil {
		return nil, err
	}

	fields := map[string]any{}
	if req.Name != nil {
		name := strings.TrimSpace(*req.Name)
		if name == "" {
			return nil, httpx.FieldViolation("name", "required")
		}
		fields["name"] = name
	}
	if req.Phone != nil {
		phone, ok := NormalizePhone(*req.Phone)
		if !ok {
			return nil, httpx.FieldViolation("phone", "phone")
		}
		fields["phone"] = phone // nil clears the column
	}

	if len(fields) > 0 {
		if err := s.repo.Update(ctx, id, fields); err != nil {
			return nil, fmt.Errorf("update customer: %w", err)
		}
	}
	return s.Get(ctx, id)
}

// Resolve returns the customer for an order: the one with the given id, or the existing customer with the
// same name (case-insensitive) and normalized phone, or a newly created one.
func (s *Service) Resolve(ctx context.Context, id *uuid.UUID, name, phone string) (*model.Customer, error) {
	if id != nil {
		c, err := s.repo.FindByID(ctx, *id)
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, httpx.NotFound("customer not found")
		}
		if err != nil {
			return nil, fmt.Errorf("find customer: %w", err)
		}
		return c, nil
	}

	name = strings.TrimSpace(name)
	if name == "" {
		return nil, httpx.FieldViolation("customer.name", "required")
	}
	normalized, ok := NormalizePhone(phone)
	if !ok {
		return nil, httpx.FieldViolation("customer.phone", "phone")
	}

	existing, err := s.repo.FindByNameAndPhone(ctx, name, normalized)
	if err == nil {
		return existing, nil
	}
	if !errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, fmt.Errorf("find customer by name and phone: %w", err)
	}

	c := &model.Customer{Name: name, Phone: normalized}
	if err := s.repo.Create(ctx, c); err != nil {
		return nil, fmt.Errorf("create customer: %w", err)
	}
	return c, nil
}

func (s *Service) TouchLastOrder(ctx context.Context, id uuid.UUID, at time.Time) error {
	if err := s.repo.TouchLastOrder(ctx, id, at); err != nil {
		return fmt.Errorf("touch customer last order: %w", err)
	}
	return nil
}
