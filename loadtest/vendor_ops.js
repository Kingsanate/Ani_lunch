// Vendor operations — the kitchen loop. Each VU is a vendor: polls its own
// order queue (GET /vendors/me/orders) and advances orders
// pending → preparing → ready_for_pickup.
//
// Setup seeds a pool of pending orders (COD) per vendor so transitions have
// work to do; the guarded UPDATE makes double-advances impossible, so
// conflicts are expected under concurrency and tracked separately.
//
// Run: k6 run -e VUS=25 -e SEED_PER_VENDOR=8 loadtest/vendor_ops.js

import http from 'k6/http';
import { check, sleep } from 'k6';
import { API, authHeaders, checkOk, CUSTOMER_IDS, VENDOR_IDS } from './lib/helpers.js';

export const options = {
  scenarios: {
    vendor: {
      executor: 'per-vu-iterations',
      vus: __ENV.VUS ? Number(__ENV.VUS) : 25,
      iterations: 20,
      maxDuration: '15m',
      exec: 'vendorLoop',
    },
  },
  thresholds: {
    http_req_failed: ['rate<0.01'],
    http_req_duration: ['p(95)<400', 'p(99)<800'],
  },
};

// Seed pending orders for every vendor so the loop always has work.
export function setup() {
  const perVendor = __ENV.SEED_PER_VENDOR ? Number(__ENV.SEED_PER_VENDOR) : 8;
  const orders = []; // [{id, vendor_id}]

  VENDOR_IDS.forEach((vendorId, vi) => {
    const customer = CUSTOMER_IDS[vi % CUSTOMER_IDS.length];
    const headers = authHeaders(customer, 'customer');
    for (let i = 0; i < perVendor; i++) {
      const meatId = (vi * 7 + i) % 400 + 1;
      const body = {
        vendor_id: vendorId,
        order_type: 'meat',
        items: [{ product_id: meatId, product_type: 'meat', name: `Item ${meatId}`, price: (300 + (meatId % 40) * 25) * 100, image: null, quantity: 1 }],
        delivery_address: 'Load Test Address',
        delivery_street: 'MG Road',
        delivery_city: 'Shillong',
        delivery_zip: '793001',
        delivery_lat: 25.57, delivery_lng: 91.88,
        payment_method: 'cod',
        special_notes: 'vendor-ops seed',
        idempotency_key: `lt-vendor-${vendorId}-${i}`,
      };
      const res = http.post(`${API}/orders`, JSON.stringify(body), { headers });
      if (checkOk(res, `seed order for ${vendorId}`) && res.json().data) {
        orders.push({ id: res.json().data.id, vendor_id: vendorId });
      }
    }
  });
  return { orders };
}

export function vendorLoop(data) {
  const vendorId = VENDOR_IDS[__VU % VENDOR_IDS.length];
  const headers = authHeaders(vendorId, 'vendor');

  const queue = http.get(`${API}/vendors/me/orders`, { headers });
  check(queue, { 'vendor queue 200': (r) => r.status === 200 });
  if (!checkOk(queue, 'vendors/me/orders')) {
    sleep(1);
    return;
  }

  const list = queue.json().data || [];
  let advanced = 0;
  for (const order of list) {
    if (advanced >= 2) break; // bounded work per iteration
    if (order.status === 'pending') {
      const t1 = http.post(`${API}/orders/${order.id}/transition`,
        JSON.stringify({ status: 'preparing' }), { headers });
      if (t1.status === 200) {
        const t2 = http.post(`${API}/orders/${order.id}/transition`,
          JSON.stringify({ status: 'ready_for_pickup' }), { headers });
        check(t2, { 'ready_for_pickup 200': (r) => r.status === 200 });
        advanced += 1;
      } else {
        checkOk(t1, `transition pending→preparing ${order.id}`);
      }
    }
  }

  sleep(1 + Math.random() * 2);
}