package order

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"

	"jesi-laundry-app-server/internal/platform/timeutil"
)

// FormatOrderNumber renders {OUTLET_CODE}-{YYMMDD}-{NNNN} for the business-local date of now.
func FormatOrderNumber(outletCode string, now time.Time, sequence int) string {
	return fmt.Sprintf("%s-%s-%04d", outletCode, now.In(timeutil.Location()).Format("060102"), sequence)
}

// nextOrderNumber atomically takes the next sequence for the outlet and local day.
// It must run inside the order-creation transaction (repo bound to tx).
func nextOrderNumber(ctx context.Context, repo *Repository, outletID uuid.UUID, outletCode string, now time.Time) (string, error) {
	seq, err := repo.NextSequence(ctx, outletID, timeutil.LocalDate(now), now)
	if err != nil {
		return "", fmt.Errorf("next order sequence: %w", err)
	}
	return FormatOrderNumber(outletCode, now, seq), nil
}
