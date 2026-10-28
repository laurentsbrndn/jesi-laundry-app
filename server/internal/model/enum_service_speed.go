package model

type ServiceSpeed string

const (
	SpeedRegular ServiceSpeed = "regular"
	SpeedExpress ServiceSpeed = "express"
)

func (s ServiceSpeed) IsValid() bool {
	return s == SpeedRegular || s == SpeedExpress
}
