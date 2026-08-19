// Cart → checkout → order flow. The cart itself is client-side (Drift); the
// server work is order creation: snapshot items, idempotency key, coupon
// validation, address + GPS, payment method.
//
// COD dominates (no Razorpay dependency). The online-intent path can be
// enabled with -e CREATE_INTENT=1 when Razorpay sandbox keys are reachable
// from the test box — the API calls Razorpay at create-intent time.
//
// Run: k6 run -e VUS=100 -e ITER=40 loadtest/cart_flow.js

import http from 'k6/http';
import { check, sleep } from 'k6';
import { API, authHeaders, checkOk, CUSTOMER_IDS, VENDOR_IDS } from './lib/helpers.js';

export const options = {
  scenarios: {
    checkout: {
      executor: 'per-vu-iterations',
      vus: __ENV.VUS ? Number(__ENV.VUS) : 100,
      iterations: __ENV.ITER ? Number(__ENV.ITER) : 40,
      maxDuration: '15m',
    },
  },
  thresholds: {
    http_req_failed: ['rate<0.01'],
    http_req_duration: ['p(95)<400', 'p(99)<800'],
  },
};

export default function () {
  const customer = CUSTOMER_IDS[__VU % CUSTOMER_IDS.length];
  const headers = authHeaders(customer, 'customer');

  // Deterministic item selection per VU (meat item id 1..400, lunch id 1..40).
  const meatId = (__VU % 400) + 1;
  const lunchId = (__VU % 40) + 1;
  const useLunch = __VU % 3 === 0; // 1/3 of orders are lunch combos

  const items = useLunch
    ? [{ product_id: lunchId, product_type: 'lunch', name: `Lunch ${lunchId}`, price: (150 + (lunchId % 20) * 20) * 100, image: null, quantity: 1 }]
    : [{ product_id: meatId, product_type: 'meat', name: `Item ${meatId}`, price: (300 + (meatId % 40) * 25) * 100, image: null, quantity: 1 }];

  const body = {
    vendor_id: useLunch ? null : VENDOR_IDS[__VU % VENDOR_IDS.length],
    order_type: useLunch ? 'lunch' : 'meat',
    items,
    delivery_address: 'Load Test Address',
    delivery_street: 'MG Road',
    delivery_city: 'Shillong',
    delivery_zip: '793001',
    delivery_lat: 25.57 + (__VU % 10) * 0.001,
    delivery_lng: 91.88 + (__VU % 10) * 0.001,
    payment_method: 'cod',
    coupon_code: __VU % 4 === 0 ? 'LT10' : null,
    special_notes: 'loadtest',
    idempotency_key: `lt-${__VU}-${Date.now()}`,
  };

  const create = http.post(`${API}/orders`, JSON.stringify(body), { headers });
  check(create, { 'create order 201/200': (r) => r.status === 200 || r.status === 201 });
  if (!checkOk(create, 'orders/create')) {
    sleep(1);
    return;
  }

  const order = create.json().data;
  const orderId = order && order.id;

  if (orderId) {
    // Follow-up: verify the order projection (what the customer app shows).
    const get = http.get(`${API}/orders/${orderId}`, { headers });
    check(get, { 'get order 200': (r) => r.status === 200 });

    // Some customers cancel shortly after ordering.
    if (__VU % 7 === 0) {
      const cancel = http.post(`${API}/orders/${orderId}/cancel`, '{}', { headers });
      check(cancel, { 'cancel order 200': (r) => r.status === 200 });
    }

    // Optional online-intent path (Razorpay sandbox required).
    if (__ENV.CREATE_INTENT === '1' && __VU % 5 === 0) {
      const intent = http.post(`${API}/payments/create-intent`,
        JSON.stringify({ order_id: orderId, payment_method: 'online' }), { headers });
      checkOk(intent, 'payments/create-intent');
    }
  }

  sleep(1 + Math.random() * 2);
}