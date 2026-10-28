package httpx

// Page holds the standard list query parameters; embed it in list query DTOs.
type Page struct {
	Page  int `query:"page" validate:"omitempty,gte=1"`
	Limit int `query:"limit" validate:"omitempty,gte=1"`
}

// Normalize applies defaults and clamps Limit to maxLimit.
func (p Page) Normalize(defaultLimit, maxLimit int) Page {
	if p.Page < 1 {
		p.Page = 1
	}
	if p.Limit < 1 {
		p.Limit = defaultLimit
	}
	if p.Limit > maxLimit {
		p.Limit = maxLimit
	}
	return p
}

func (p Page) Offset() int { return (p.Page - 1) * p.Limit }

func (p Page) Meta(total int64) Meta {
	return Meta{Page: p.Page, Limit: p.Limit, Total: total}
}
