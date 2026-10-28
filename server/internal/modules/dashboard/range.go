package dashboard

import "time"

// Bucket granularities of the time series.
const (
	bucketFiveMin = "5m"
	bucketHour    = "hour"
	bucketDay     = "day"
	bucketMonth   = "month"
	bucketYear    = "year"
)

const defaultRange = "24h"

// RangeSpec describes one rolling range and the bucket size used for its series.
type RangeSpec struct {
	Name   string
	Bucket string
}

var ranges = map[string]RangeSpec{
	"1h":  {Name: "1h", Bucket: bucketFiveMin},
	"24h": {Name: "24h", Bucket: bucketHour},
	"7d":  {Name: "7d", Bucket: bucketDay},
	"30d": {Name: "30d", Bucket: bucketDay},
	"1y":  {Name: "1y", Bucket: bucketMonth},
	// "all" starts at the first order; its bucket is chosen by AllBucket once that time is known.
	"all": {Name: "all", Bucket: bucketMonth},
}

// ParseRange resolves a range name; an empty name means the default (24h).
func ParseRange(name string) (RangeSpec, bool) {
	if name == "" {
		name = defaultRange
	}
	spec, ok := ranges[name]
	return spec, ok
}

// maxMonthlyBuckets is the largest calendar-month span of "all" that still uses month buckets.
const maxMonthlyBuckets = 24

// Window returns the rolling [from, to] window ending at now. Day and year offsets are calendar
// offsets in the business time zone. It is not meaningful for "all", whose start comes from the data.
func (r RangeSpec) Window(now time.Time, loc *time.Location) (from, to time.Time) {
	local := now.In(loc)
	switch r.Name {
	case "1h":
		from = local.Add(-time.Hour)
	case "24h":
		from = local.Add(-24 * time.Hour)
	case "7d":
		from = local.AddDate(0, 0, -7)
	case "30d":
		from = local.AddDate(0, 0, -30)
	default: // 1y
		from = local.AddDate(-1, 0, 0)
	}
	return from.UTC(), now.UTC()
}

// bucketStart aligns t to the start of its bucket on the business-local wall clock,
// matching PostgreSQL's date_trunc / date_bin on `created_at AT TIME ZONE tz`.
func bucketStart(bucket string, t time.Time, loc *time.Location) time.Time {
	l := t.In(loc)
	y, m, d := l.Date()
	switch bucket {
	case bucketFiveMin:
		return time.Date(y, m, d, l.Hour(), l.Minute()-l.Minute()%5, 0, 0, loc)
	case bucketHour:
		return time.Date(y, m, d, l.Hour(), 0, 0, 0, loc)
	case bucketDay:
		return time.Date(y, m, d, 0, 0, 0, 0, loc)
	case bucketYear:
		return time.Date(y, 1, 1, 0, 0, 0, 0, loc)
	default: // month
		return time.Date(y, m, 1, 0, 0, 0, 0, loc)
	}
}

// AllBucket picks the bucket for "all": month while the calendar-month span between from and to
// (business zone) is at most 24, otherwise year.
func AllBucket(from, to time.Time, loc *time.Location) string {
	f, t := from.In(loc), to.In(loc)
	months := (t.Year()-f.Year())*12 + int(t.Month()) - int(f.Month())
	if months <= maxMonthlyBuckets {
		return bucketMonth
	}
	return bucketYear
}

// nextBucket returns the start of the bucket after the one starting at start.
func nextBucket(bucket string, start time.Time, loc *time.Location) time.Time {
	y, m, d := start.Date()
	switch bucket {
	case bucketFiveMin:
		return start.Add(5 * time.Minute)
	case bucketHour:
		return start.Add(time.Hour)
	case bucketDay:
		return time.Date(y, m, d+1, 0, 0, 0, 0, loc)
	case bucketYear:
		return time.Date(y+1, 1, 1, 0, 0, 0, 0, loc)
	default: // month
		return time.Date(y, m+1, 1, 0, 0, 0, 0, loc)
	}
}

// buckets lists every bucket start from the bucket containing from to the bucket containing to.
func buckets(bucket string, from, to time.Time, loc *time.Location) []time.Time {
	last := bucketStart(bucket, to, loc)
	var out []time.Time
	for b := bucketStart(bucket, from, loc); !b.After(last); b = nextBucket(bucket, b, loc) {
		out = append(out, b)
	}
	return out
}

// wallToLocal converts a PostgreSQL `timestamp without time zone` (scanned as UTC-labelled wall time)
// into the same wall time in the business zone.
func wallToLocal(t time.Time, loc *time.Location) time.Time {
	return time.Date(t.Year(), t.Month(), t.Day(), t.Hour(), t.Minute(), t.Second(), 0, loc)
}
