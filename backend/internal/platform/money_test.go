package platform

import (
	"testing"
)

func TestMoney_FromRupees(t *testing.T) {
	tests := []struct {
		name     string
		input    float64
		expected Money
	}{
		{"zero", 0.0, 0},
		{"integer rupees", 100.0, 10000},
		{"rupees with paise", 129.99, 12999},
		{"single digit paise", 45.5, 4550},
		{"fractional precision round", 99.999, 10000},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := FromRupees(tt.input)
			if got != tt.expected {
				t.Errorf("FromRupees(%v) = %v, expected %v", tt.input, got, tt.expected)
			}
		})
	}
}

func TestMoney_Arithmetic(t *testing.T) {
	m1 := FromRupees(150.00) // 15000 paise
	m2 := FromRupees(50.00)  // 5000 paise

	// Add
	if got := m1.Add(m2); got != 20000 {
		t.Errorf("Add failed: got %v, expected 20000", got)
	}

	// Subtract
	if got := m1.Subtract(m2); got != 10000 {
		t.Errorf("Subtract failed: got %v, expected 10000", got)
	}

	// Subtract to negative clamp
	if got := m2.Subtract(m1); got != 0 {
		t.Errorf("Subtract clamped to 0 failed: got %v, expected 0", got)
	}

	// Multiply
	if got := m2.MultiplyByQuantity(3); got != 15000 {
		t.Errorf("MultiplyByQuantity failed: got %v, expected 15000", got)
	}

	// Percent discount
	total := FromRupees(500.00) // 50000 paise
	discount := total.ApplyPercentDiscount(10.0, FromRupees(100.00))
	if discount != 5000 { // ₹50
		t.Errorf("ApplyPercentDiscount failed: got %v, expected 5000", discount)
	}

	// Discount capped by max discount
	discountCapped := total.ApplyPercentDiscount(50.0, FromRupees(100.00))
	if discountCapped != 10000 { // ₹100 max cap
		t.Errorf("ApplyPercentDiscount cap failed: got %v, expected 10000", discountCapped)
	}
}

func TestMoney_Formatting(t *testing.T) {
	m := FromRupees(249.50)
	if m.String() != "₹249.50" {
		t.Errorf("String() = %v, expected ₹249.50", m.String())
	}
}
