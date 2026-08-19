package orders

import (
	"testing"

	"animeat/backend/internal/platform"
)

func TestApplyFlatDiscount(t *testing.T) {
	tests := []struct {
		name         string
		flatPaise    int64
		subtotal     platform.Money
		maxDiscount  platform.Money
		expectedPaise int64
	}{
		{
			name:         "flat discount within limits",
			flatPaise:    5000, // ₹50
			subtotal:     platform.FromRupees(400.00),
			maxDiscount:  platform.FromRupees(100.00),
			expectedPaise: 5000,
		},
		{
			name:         "flat discount capped by max discount",
			flatPaise:    15000, // ₹150
			subtotal:     platform.FromRupees(400.00),
			maxDiscount:  platform.FromRupees(100.00),
			expectedPaise: 10000, // capped at ₹100
		},
		{
			name:         "flat discount capped by subtotal",
			flatPaise:    50000, // ₹500
			subtotal:     platform.FromRupees(200.00),
			maxDiscount:  0, // no max
			expectedPaise: 20000, // capped at ₹200
		},
		{
			name:         "zero max discount means unlimited",
			flatPaise:    3000,
			subtotal:     platform.FromRupees(500.00),
			maxDiscount:  0,
			expectedPaise: 3000,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := applyFlatDiscount(tt.flatPaise, tt.subtotal, tt.maxDiscount)
			if got.ToPaise() != tt.expectedPaise {
				t.Fatalf("expected %d paise, got %d", tt.expectedPaise, got.ToPaise())
			}
		})
	}
}

func TestCalculatePricingRejectsMismatchedLengths(t *testing.T) {
	_, err := CalculatePricing(
		[]platform.Money{platform.FromRupees(100)},
		[]int{1, 2},
		0, 0, 0,
	)
	if err == nil {
		t.Fatal("expected error for mismatched lengths")
	}
}

func TestCalculatePricing(t *testing.T) {
	tests := []struct {
		name              string
		prices            []platform.Money
		quantities        []int
		couponDiscountPct float64
		maxCouponDiscount platform.Money
		minCouponOrderAmt platform.Money
		expectedSubtotal  platform.Money
		expectedDelivery  platform.Money
		expectedDiscount  platform.Money
		expectedTotal     platform.Money
	}{
		{
			name:              "single item with delivery fee",
			prices:            []platform.Money{platform.FromRupees(150.00)}, // 15000 paise
			quantities:        []int{1},
			couponDiscountPct: 0,
			maxCouponDiscount: 0,
			minCouponOrderAmt: 0,
			expectedSubtotal:  15000,
			expectedDelivery:  3000, // ₹30
			expectedDiscount:  0,
			expectedTotal:     18000, // ₹180
		},
		{
			name:              "multiple items over ₹500 qualifying for free delivery",
			prices:            []platform.Money{platform.FromRupees(200.00), platform.FromRupees(350.00)},
			quantities:        []int{1, 1},
			couponDiscountPct: 0,
			maxCouponDiscount: 0,
			minCouponOrderAmt: 0,
			expectedSubtotal:  55000, // ₹550
			expectedDelivery:  0,     // Free delivery >= ₹500
			expectedDiscount:  0,
			expectedTotal:     55000,
		},
		{
			name:              "order with valid 10% coupon discount",
			prices:            []platform.Money{platform.FromRupees(400.00)},
			quantities:        []int{1},
			couponDiscountPct: 10.0,
			maxCouponDiscount: platform.FromRupees(100.00),
			minCouponOrderAmt: platform.FromRupees(200.00),
			expectedSubtotal:  40000, // ₹400
			expectedDelivery:  3000,  // ₹30
			expectedDiscount:  4000,  // ₹40 (10% of 400)
			expectedTotal:     39000, // ₹400 + ₹30 - ₹40 = ₹390
		},
		{
			name:              "coupon discount capped at max limit",
			prices:            []platform.Money{platform.FromRupees(1000.00)},
			quantities:        []int{1},
			couponDiscountPct: 50.0,
			maxCouponDiscount: platform.FromRupees(100.00), // Max ₹100
			minCouponOrderAmt: platform.FromRupees(200.00),
			expectedSubtotal:  100000, // ₹1000
			expectedDelivery:  0,      // Free delivery
			expectedDiscount:  10000,  // Capped at ₹100
			expectedTotal:     90000,  // ₹900
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			pricing, err := CalculatePricing(
				tt.prices, tt.quantities,
				tt.couponDiscountPct, tt.maxCouponDiscount, tt.minCouponOrderAmt,
			)
			if err != nil {
				t.Fatalf("unexpected error: %v", err)
			}

			if pricing.Subtotal != tt.expectedSubtotal {
				t.Errorf("Subtotal = %v, expected %v", pricing.Subtotal, tt.expectedSubtotal)
			}
			if pricing.DeliveryFee != tt.expectedDelivery {
				t.Errorf("DeliveryFee = %v, expected %v", pricing.DeliveryFee, tt.expectedDelivery)
			}
			if pricing.Discount != tt.expectedDiscount {
				t.Errorf("Discount = %v, expected %v", pricing.Discount, tt.expectedDiscount)
			}
			if pricing.TotalAmount != tt.expectedTotal {
				t.Errorf("TotalAmount = %v, expected %v", pricing.TotalAmount, tt.expectedTotal)
			}
		})
	}
}

func TestApplyCustomizationPricing(t *testing.T) {
	tests := []struct {
		name           string
		base           platform.Money
		customizations map[string]string
		expectedPaise  int64
	}{
		{
			name:          "no customizations leaves price unchanged",
			base:          platform.FromRupees(100.00),
			expectedPaise: 10000,
		},
		{
			name:           "empty meat spec leaves price unchanged",
			base:           platform.FromRupees(100.00),
			customizations: map[string]string{"Rice": "Plain Rice"},
			expectedPaise:  10000,
		},
		{
			name:           "single piece has no extra charge",
			base:           platform.FromRupees(150.00),
			customizations: map[string]string{"Meat": "1x Chicken"},
			expectedPaise:  15000,
		},
		{
			name:           "two pieces adds one extra charge",
			base:           platform.FromRupees(150.00),
			customizations: map[string]string{"Meat": "2x Chicken"},
			expectedPaise:  17000, // ₹150 + ₹20
		},
		{
			name:           "three pieces across options",
			base:           platform.FromRupees(150.00),
			customizations: map[string]string{"Meat": "2x Chicken, 1x Mutton"},
			expectedPaise:  19000, // ₹150 + 2×₹20
		},
		{
			name:           "malformed pieces are ignored",
			base:           platform.FromRupees(100.00),
			customizations: map[string]string{"Meat": "x Chicken, unknown"},
			expectedPaise:  10000,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := ApplyCustomizationPricing(tt.base, tt.customizations)
			if got.ToPaise() != tt.expectedPaise {
				t.Fatalf("expected %d paise, got %d", tt.expectedPaise, got.ToPaise())
			}
		})
	}
}

func TestResolveOrderType(t *testing.T) {
	tests := []struct {
		name            string
		explicit        *string
		usesLunchCatalog bool
		expected        string
		wantErr         bool
	}{
		{name: "explicit meat wins", explicit: strPtr("meat"), usesLunchCatalog: true, expected: "meat"},
		{name: "explicit lunch wins", explicit: strPtr("lunch"), usesLunchCatalog: false, expected: "lunch"},
		{name: "inferred meat when no explicit and no lunch items", explicit: nil, usesLunchCatalog: false, expected: "meat"},
		{name: "inferred lunch from lunch catalog items", explicit: nil, usesLunchCatalog: true, expected: "lunch"},
		{name: "rejects invalid explicit value", explicit: strPtr("breakfast"), wantErr: true},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			got, err := ResolveOrderType(tc.explicit, tc.usesLunchCatalog)
			if tc.wantErr {
				if err == nil {
					t.Fatalf("expected error, got %q", got)
				}
				return
			}
			if err != nil {
				t.Fatalf("unexpected error: %v", err)
			}
			if got != tc.expected {
				t.Fatalf("expected %q, got %q", tc.expected, got)
			}
		})
	}
}

func strPtr(s string) *string { return &s }
