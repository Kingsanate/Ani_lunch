package platform

import (
	"fmt"
	"math"
	"strconv"
	"strings"
)

// Money represents a monetary amount stored strictly in integer minor units (e.g. Paise for INR).
// ₹100.50 is represented as 10050 paise. Never use floating-point arithmetic for money.
type Money int64

// FromRupees converts a float rupee value (e.g. 100.50) into Money (10050 paise) using safe rounding.
func FromRupees(rupees float64) Money {
	return Money(math.Round(rupees * 100))
}

// FromPaise creates a Money instance from integer paise.
func FromPaise(paise int64) Money {
	return Money(paise)
}

// ParseRupees parses a rupee string (e.g. "100.50" or "₹100.50") into Money.
func ParseRupees(s string) (Money, error) {
	cleaned := strings.TrimSpace(s)
	cleaned = strings.TrimPrefix(cleaned, "₹")
	cleaned = strings.TrimPrefix(cleaned, "Rs.")
	cleaned = strings.TrimPrefix(cleaned, "Rs")
	cleaned = strings.TrimSpace(cleaned)

	val, err := strconv.ParseFloat(cleaned, 64)
	if err != nil {
		return 0, fmt.Errorf("invalid rupee format: %w", err)
	}
	return FromRupees(val), nil
}

// ToPaise returns the integer paise value.
func (m Money) ToPaise() int64 {
	return int64(m)
}

// ToRupees returns the floating-point rupee value for presentation/external serialization only.
func (m Money) ToRupees() float64 {
	return float64(m) / 100.0
}

// String returns formatted currency string, e.g. "₹100.50".
func (m Money) String() string {
	rupees := m / 100
	paise := m % 100
	if paise < 0 {
		paise = -paise
	}
	return fmt.Sprintf("₹%d.%02d", rupees, paise)
}

// Add safely adds two Money amounts.
func (m Money) Add(other Money) Money {
	return m + other
}

// Subtract safely subtracts two Money amounts, clamping to zero if specified.
func (m Money) Subtract(other Money) Money {
	res := m - other
	if res < 0 {
		return 0
	}
	return res
}

// MultiplyByQuantity multiplies unit price by quantity.
func (m Money) MultiplyByQuantity(qty int) Money {
	if qty <= 0 {
		return 0
	}
	return m * Money(qty)
}

// ApplyPercentDiscount calculates discount in integer paise with floor clamping.
func (m Money) ApplyPercentDiscount(percent float64, maxDiscount Money) Money {
	if percent <= 0 {
		return 0
	}
	if percent > 100 {
		percent = 100
	}

	discount := Money(math.Round(float64(m) * (percent / 100.0)))
	if maxDiscount > 0 && discount > maxDiscount {
		discount = maxDiscount
	}
	if discount > m {
		discount = m
	}
	return discount
}
