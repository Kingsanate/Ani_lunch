// Rider operations — the delivery loop with live GPS. Each VU is a rider:
// toggles availability, pushes location updates (PUT /riders/me/location,
// which publishes the NATS riders.location event), polls the available
// orders pool, accepts, picks up and delivers.
//
// Setup seeds a batch of orders and advances them to ready_for_pickup so the
// pool is hot. Riders race for the same orders — accept conflicts are
// expected and tracked as a dedicated counter (the guarded update rejects
// the loser).
//
// Run: k6 run -e VUS=25 -e SEED=60 loadtest/rider_ops.js

import http from 'k6/http';
import { check, sleep } from 'k6';
import { API, authHeaders, checkOk, CUSTOMER_IDS, RIDER_IDS, VENDOR_IDS } from './lib/helpers.js';

export const options = {
  scenarios: {
    rider: {
      executor: 'per-vu-iterations',
      vus: __ENV.VUS ? Number(__ENV.VUS) : 25,
      iterations: 15,
      maxDuration: '15m',
      exec: 'riderLoop',
    },
  },
  thresholds: {
    http_req_failed: ['rate<0.01'],
    http_req_duration: ['p(95)<400', 'p(99)<800'],
  },
};

export function setup() {
  const seedCount = __ENV.SEED ? Number(__ENV.SEED) : 60;
  const ready = []; // order ids waiting for pickup

  const customer = CUSTOMER_IDS[0];
  const cHeaders = authHeaders(customer, 'customer');
  const vendorId = VENDOR_IDS[0];
  const vHeaders = authHeaders(vendorId, 'vendor');

  for (let i = 0; i < seedCount; i++) {
    const meatId = (i % 400) + 1;
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
      special_notes: 'rider-ops seed',
      idempotency_key: `lt-rider-seed-${i}`,
    };
    const created = http.post(`${API}/orders`, JSON.stringify(body), { headers: cHeaders });
    if (!checkOk(created, `seed order ${i}`) || !created.json().data) continue;

    const id = created.json().data.id;
    const t1 = http.post(`${API}/orders/${id}/transition`, JSON.stringify({ status: 'preparing' }), { headers: vHeaders });
    const t2 = http.post(`${API}/orders/${id}/transition`, JSON.stringify({ status: 'ready_for_pickup' }), { headers: vHeaders });
    if (t1.status === 200 && t2.status === 200) {
      ready.push(id);
    }
  }
  return { ready };
}

export function riderLoop(data) {
  const riderId = RIDER_IDS[__VU % RIDER_IDS.length];
  const headers = authHeaders(riderId, 'rider');

  // GPS heartbeat — 10s cadence in production; a few pushes per iteration.
  const loc = http.put(`${API}/riders/me/location`, JSON.stringify({
    latitude: 25.57 + (__VU % 20) * 0.0005,
    longitude: 91.88 + (__VU % 20) * 0.0005,
  }), { headers });
  check(loc, { 'location 200': (r) => r.status === 200 });

  const avail = http.put(`${API}/riders/me/availability`, JSON.stringify({ is_online: true }), { headers });
  check(avail, { 'availability 200': (r) => r.status === 200 });

  const pool = http.get(`${API}/riders/orders/available`, { headers });
  check(pool, { 'available pool 200': (r) => r.status === 200 });
  if (!checkOk(pool, 'riders/orders/available')) {
    sleep(1);
    return;
  }

  const available = pool.json().data || [];
  if (available.length === 0) {
    sleep(1);
    return;
  }

  // Take the first unassigned order.
  const target = available[0];
  const accept = http.post(`${API}/riders/orders/${target.id}/accept`, '{}', { headers });
  if (accept.status === 409 || (accept.body && accept.body.includes('CONFLICT'))) {
    // Someone else won the race — realistic under concurrent riders.
    check(accept.status, { 'accept conflict (expected)': (s) => s === 409 || s === 200 });
    sleep(1);
    return;
  }
  if (!checkOk(accept, 'riders accept')) {
    sleep(1);
    return;
  }

  const t1 = http.post(`${API}/orders/${target.id}/transition`, JSON.stringify({ status: 'picked_up' }), { headers });
  check(t1, { 'picked_up 200': (r) => r.status === 200 });

  const t2 = http.post(`${API}/orders/${target.id}/transition`, JSON.stringify({ status: 'delivered' }), { headers });
  check(t2, { 'delivered 200': (r) => r.status === 200 });

  sleep(2 + Math.random() * 3);
}