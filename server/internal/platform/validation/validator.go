package validation

import (
	"reflect"
	"strings"

	"github.com/go-playground/validator/v10"
)

var instance = newValidator()

// Validator returns the shared validator instance.
func Validator() *validator.Validate { return instance }

func newValidator() *validator.Validate {
	v := validator.New(validator.WithRequiredStructEnabled())
	// Report errors with the JSON/query name so clients see the field they sent.
	v.RegisterTagNameFunc(func(f reflect.StructField) string {
		for _, key := range []string{"json", "query"} {
			if name := strings.SplitN(f.Tag.Get(key), ",", 2)[0]; name != "" && name != "-" {
				return name
			}
		}
		return f.Name
	})
	return v
}
