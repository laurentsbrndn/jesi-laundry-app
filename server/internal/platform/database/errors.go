package database

import (
	"errors"

	"github.com/jackc/pgx/v5/pgconn"
)

const pgUniqueViolation = "23505"

// UniqueViolation reports whether err is a PostgreSQL unique violation and returns the violated constraint/index name.
func UniqueViolation(err error) (constraint string, ok bool) {
	var pgErr *pgconn.PgError
	if errors.As(err, &pgErr) && pgErr.Code == pgUniqueViolation {
		return pgErr.ConstraintName, true
	}
	return "", false
}
