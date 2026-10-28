package model

type Role string

const (
	RoleOwner Role = "owner"
	RoleStaff Role = "staff"
)

func (r Role) IsValid() bool {
	return r == RoleOwner || r == RoleStaff
}
