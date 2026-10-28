package timeutil

import (
	"fmt"
	"time"
)

var loc = time.UTC

// Init sets the business time zone (APP_TIMEZONE). Call once at startup.
func Init(l *time.Location) {
	if l != nil {
		loc = l
	}
}

// Location returns the business time zone.
func Location() *time.Location { return loc }

// LocalDate returns the business-local calendar date of t as midnight UTC,
// which is the form to store in a PostgreSQL date column.
func LocalDate(t time.Time) time.Time {
	y, m, d := t.In(loc).Date()
	return time.Date(y, m, d, 0, 0, 0, 0, time.UTC)
}

// StartOfDay returns the instant at which t's business-local day began.
func StartOfDay(t time.Time) time.Time {
	y, m, d := t.In(loc).Date()
	return time.Date(y, m, d, 0, 0, 0, 0, loc)
}

// ParseDate parses a YYYY-MM-DD string as midnight in the business time zone.
func ParseDate(s string) (time.Time, error) {
	t, err := time.ParseInLocation("2006-01-02", s, loc)
	if err != nil {
		return time.Time{}, fmt.Errorf("parse date %q: %w", s, err)
	}
	return t, nil
}
