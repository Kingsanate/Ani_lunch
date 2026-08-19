// AniMeat full-profile load runner — the canonical Phase 10 entry point.
//
// Runs all traffic classes concurrently with real-world proportions
// (≈50% browse, 25% menu, 10% search, 8% checkout, 4% tracking, 1.5% vendor,
// 1.5% rider) at a configurable concurrency tier.
//
//   TIER=1k   → ~1,000 concurrent users  (smoke / soak)
//   TIER=5k   → ~5,000 concurrent users
//   TIER=10k  → ~10,000 concurrent users (sprint goal)
//   TIER=100k → ~100,000 concurrent users (stretch; distributed k6 agents)
//
// Usage:
//   k6 run -e TIER=1k -e DURATION=5m loadtest/scenarios.js
//   k6 run -e TIER=100k -e DURATION=15m loadtest/scenarios.js --max-vus 100000
//
// See loadtest/README.md for the full runbook.

import http from 'k6/http';
import { check, sleep } from 'k6';
import ws from 'k6/ws';
import {
  API, authHeaders, checkOk, CUSTOMER_IDS, RIDER_IDS, VENDOR_IDS,
} from './lib/helpers.js';

const TIER = __ENV.TIER || '1k';
const DURATION = __ENV.DURATION || '5m';

// VU allocation per tier (sum ≈ tier size). Override per-scenario with
// -e VUS_<scenario>=N.
const TIERS = {
  '1k':   { browse: 500, menu: 250, search: 100, checkout: 80,  track: 40,  vendor: 15, rider: 15 },
  '5k':   { browse: 2500, menu: 1250, search: 500, checkout: 400, track: 200, vendor: 75, rider: 75 },
  '10k':  { browse: 5000, menu: 2500, search: 1000, checkout: 800, track: 400, vendor: 150, rider: 150 },
  '100k': { browse: 50000, menu: 25000, search: 10000, checkout: 8000, track: 4000, vendor: 1500, rider: 1500 },
};

function vusFor(name) {
  return __ENV[`VUS_${name}`] ? Number(__ENV[`VUS_${name}`]) : (TIERS[TIER] ? TIERS[TIER][name] : TIERS['1k'][name]);
}

export const options = {
  scenarios: {
    browse:   { executor: 'per-vu-iterations', vus: vusFor('browse'), iterations: 20, maxDuration: DURATION, exec: 'browse' },
    menu:     { executor: 'per-vu-iterations', vus: vusFor('menu'), iterations: 15, maxDuration: DURATION, exec: 'menu' },
    search:   { executor: 'per-vu-iterations', vus: vusFor('search'), iterations: 20, maxDuration: DURATION, exec: 'search' },
    checkout: { executor: 'per-vu-iterations', vus: vusFor('checkout'), iterations: 25, maxDuration: DURATION, exec: 'checkout' },
    track:    { executor: 'per-vu-iterations', vus: vusFor('track'), iterations: 5, maxDuration: DURATION, exec: 'track' },
    vendor:   { executor: 'per-vu-iterations', vus: vusFor('vendor'), iterations: 20, maxDuration: DURATION, exec: 'vendor' },
    rider:    { executor: 'per-vu-iterations', vus: vusFor('rider'), iterations: 15, maxDuration: DURATION, exec: 'rider' },
  },
  thresholds: {
    http_req_failed: ['rate<0.01'],
    // Per-scenario latency budgets.
    'http_req_duration{scenario:checkout}': ['p(95)<400', 'p(99)<800'],
    'http_req_duration{scenario:track}': ['p(95)<400'],
    'http_req_duration{scenario:vendor}': ['p(95)<400', 'p(99)<800'],
    'http_req_duration{scenario:rider}': ['p(95)<400', 'p(99)<800'],
    'http_req_duration{scenario:browse}': ['p(95)<250', 'p(99)<500'],
    'http_req_duration{scenario:menu}': ['p(95)<300', 'p(99)<600'],
    'http_req_duration{scenario:search}': ['p(95)<250', 'p(99)<500'],
  },
};

// ---------------------------------------------------------------------------
// Setup — seed work pools for vendor/rider execs (pending + ready orders).
// ---------------------------------------------------------------------------
export function setup() {
  const pools = { pending: [], ready: [] };

  const vendorId = VENDOR_IDS[0];
  const vHeaders = authHeaders(vendorId, 'vendor');
  const cHeaders = authHeaders(CUSTOMER_IDS[0], 'customer');

  const seed = Math.max(40, Math.round((vusFor('vendor') + vusFor('rider')) * 0.4));
  for (let i = 0; i < seed; i++) {
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
      special_notes: 'scenarios seed',
      idempotency_key: `lt-scen-${i}`,
    };
    const created = http.post(`${API}/orders`, JSON.stringify(body), { headers: cHeaders });
    if (!checkOk(created, `seed ${i}`) || !created.json().data) continue;
    const id = created.json().data.id;
    pools.pending.push(id);

    if (i % 2 === 0) {
      const t1 = http.post(`${API}/orders/${id}/transition`, JSON.stringify({ status: 'preparing' }), { headers: vHeaders });
      const t2 = http.post(`${API}/orders/${id}/transition`, JSON.stringify({ status: 'ready_for_pickup' }), { headers: vHeaders });
      if (t1.status === 200 && t2.status === 200) pools.ready.push(id);
    }
  }
  return pools;
}

// ---------------------------------------------------------------------------
// Execs
// ---------------------------------------------------------------------------
export function browse() {
  const category = String((__VU % 8) + 1);
  const menus = http.get(`${API}/catalog/menus`);
  check(menus, { 'menus 200': (r) => r.status === 200 });
  const deals = http.get(`${API}/catalog/deals`);
  check(deals, { 'deals 200': (r) => r.status === 200 });
  const items = http.get(`${API}/catalog/items?category=${category}`);
  check(items, { 'items 200': (r) => r.status === 200 });
  sleep(2 + Math.random() * 4);
}

export function menu() {
  const category = String((__VU % 8) + 1);
  const items = http.get(`${API}/catalog/items?category=${category}`);
  check(items, { 'menu items 200': (r) => r.status === 200 });
  const deals = http.get(`${API}/catalog/deals`);
  check(deals, { 'menu deals 200': (r) => r.status === 200 });
  sleep(1 + Math.random() * 2);
}

export function search() {
  const query = __VU % 2 === 0 ? `category=${(__VU % 8) + 1}` : 'category=1';
  const res = http.get(`${API}/catalog/items?${query}`);
  check(res, { 'search 200': (r) => r.status === 200 });
  sleep(0.5 + Math.random());
}

export function checkout(data) {
  const customer = CUSTOMER_IDS[__VU % CUSTOMER_IDS.length];
  const headers = authHeaders(customer, 'customer');

  const meatId = (__VU % 400) + 1;
  const useLunch = __VU % 3 === 0;
  const items = useLunch
    ? [{ product_id: (__VU % 40) + 1, product_type: 'lunch', name: 'Lunch', price: (150 + (__VU % 20) * 20) * 100, image: null, quantity: 1 }]
    : [{ product_id: meatId, product_type: 'meat', name: `Item ${meatId}`, price: (300 + (meatId % 40) * 25) * 100, image: null, quantity: 1 }];

  const create = http.post(`${API}/orders`, JSON.stringify({
    vendor_id: useLunch ? null : VENDOR_IDS[__VU % VENDOR_IDS.length],
    order_type: useLunch ? 'lunch' : 'meat',
    items,
    delivery_address: 'Load Test Address',
    delivery_street: 'MG Road', delivery_city: 'Shillong', delivery_zip: '793001',
    delivery_lat: 25.57 + (__VU % 10) * 0.001, delivery_lng: 91.88 + (__VU % 10) * 0.001,
    payment_method: 'cod',
    coupon_code: __VU % 4 === 0 ? 'LT10' : null,
    special_notes: 'loadtest',
    idempotency_key: `lt-${__VU}-${Date.now()}`,
  }), { headers });
  if (!checkOk(create, 'orders/create')) { sleep(1); return; }

  const id = create.json().data && create.json().data.id;
  if (id) {
    http.get(`${API}/orders/${id}`, { headers });
    if (__VU % 7 === 0) {
      http.post(`${API}/orders/${id}/cancel`, '{}', { headers });
    }
  }
  sleep(1 + Math.random() * 2);
}

export function track() {
  const customer = CUSTOMER_IDS[__VU % CUSTOMER_IDS.length];
  const headers = authHeaders(customer, 'customer');
  const meatId = (__VU % 400) + 1;
  const create = http.post(`${API}/orders`, JSON.stringify({
    vendor_id: VENDOR_IDS[__VU % VENDOR_IDS.length],
    order_type: 'meat',
    items: [{ product_id: meatId, product_type: 'meat', name: `Item ${meatId}`, price: (300 + (meatId % 40) * 25) * 100, image: null, quantity: 1 }],
    delivery_address: 'Load Test Address',
    delivery_street: 'MG Road', delivery_city: 'Shillong', delivery_zip: '793001',
    delivery_lat: 25.57, delivery_lng: 91.88,
    payment_method: 'cod',
    idempotency_key: `lt-track-${__VU}-${Date.now()}`,
  }), { headers });
  if (!checkOk(create, 'tracking create') || !create.json().data) { sleep(1); return; }

  const orderId = create.json().data.id;
  const token = headers.Authorization.replace('Bearer ', '');
  const url = `${API.replace('/api/v1', '')}/api/v1/ws?token=${token}`;

  ws.connect(url, {}, (socket) => {
    socket.on('open', () => socket.send(JSON.stringify({ type: 'join', channel: `order:${orderId}` })));
    socket.on('message', () => {});
    socket.on('error', () => {});
    socket.setTimeout(() => socket.close(), 4000);
    socket.setInterval(() => socket.send(JSON.stringify({ type: 'ping' })), 2000);
  });
  sleep(1);
}

export function vendor(data) {
  const vendorId = VENDOR_IDS[__VU % VENDOR_IDS.length];
  const headers = authHeaders(vendorId, 'vendor');

  const queue = http.get(`${API}/vendors/me/orders`, { headers });
  check(queue, { 'vendor queue 200': (r) => r.status === 200 });
  if (!checkOk(queue, 'vendors/me/orders')) { sleep(1); return; }

  const list = queue.json().data || [];
  let advanced = 0;
  for (const order of list) {
    if (advanced >= 2) break;
    if (order.status === 'pending') {
      const t1 = http.post(`${API}/orders/${order.id}/transition`, JSON.stringify({ status: 'preparing' }), { headers });
      if (t1.status === 200) {
        const t2 = http.post(`${API}/orders/${order.id}/transition`, JSON.stringify({ status: 'ready_for_pickup' }), { headers });
        check(t2, { 'ready_for_pickup 200': (r) => r.status === 200 });
        advanced += 1;
      }
    }
  }
  sleep(1 + Math.random() * 2);
}

export function rider(data) {
  const riderId = RIDER_IDS[__VU % RIDER_IDS.length];
  const headers = authHeaders(riderId, 'rider');

  http.put(`${API}/riders/me/location`, JSON.stringify({
    latitude: 25.57 + (__VU % 20) * 0.0005, longitude: 91.88 + (__VU % 20) * 0.0005,
  }), { headers });
  http.put(`${API}/riders/me/availability`, JSON.stringify({ is_online: true }), { headers });

  const pool = http.get(`${API}/riders/orders/available`, { headers });
  check(pool, { 'available pool 200': (r) => r.status === 200 });
  if (!checkOk(pool, 'riders/orders/available')) { sleep(1); return; }

  const available = pool.json().data || [];
  if (available.length === 0) { sleep(1); return; }

  const target = available[0];
  const accept = http.post(`${API}/riders/orders/${target.id}/accept`, '{}', { headers });
  if (accept.status !== 200) { sleep(1); return; }

  http.post(`${API}/orders/${target.id}/transition`, JSON.stringify({ status: 'picked_up' }), { headers });
  http.post(`${API}/orders/${target.id}/transition`, JSON.stringify({ status: 'delivered' }), { headers });
  sleep(2 + Math.random() * 3);
}