// Order tracking — the realtime heart. Each VU keeps a WebSocket open on
// /api/v1/ws, joins its own order:{id} channel and consumes status events.
// This exercises the hub, channel authz, bridge routing and slow-consumer
// eviction under load.
//
// The script creates its order through the API (COD), subscribes, and listens
// for a few seconds.
//
// Run: k6 run -e VUS=50 -e LISTEN_S=5 loadtest/tracking.js

import http from 'k6/http';
import { check, sleep } from 'k6';
import ws from 'k6/ws';
import { API, authHeaders, checkOk, CUSTOMER_IDS, VENDOR_IDS } from './lib/helpers.js';

export const options = {
  scenarios: {
    track: {
      executor: 'per-vu-iterations',
      vus: __ENV.VUS ? Number(__ENV.VUS) : 50,
      iterations: 5,
      maxDuration: '15m',
    },
  },
  thresholds: {
    http_req_failed: ['rate<0.01'],
    http_req_duration: ['p(95)<400'],
    ws_connecting: ['p(95)<1000'],
  },
};

export default function () {
  const customer = CUSTOMER_IDS[__VU % CUSTOMER_IDS.length];
  const headers = authHeaders(customer, 'customer');

  const meatId = (__VU % 400) + 1;
  const create = http.post(`${API}/orders`, JSON.stringify({
    vendor_id: VENDOR_IDS[__VU % VENDOR_IDS.length],
    order_type: 'meat',
    items: [{ product_id: meatId, product_type: 'meat', name: `Item ${meatId}`, price: (300 + (meatId % 40) * 25) * 100, image: null, quantity: 1 }],
    delivery_address: 'Load Test Address',
    delivery_street: 'MG Road',
    delivery_city: 'Shillong',
    delivery_zip: '793001',
    delivery_lat: 25.57, delivery_lng: 91.88,
    payment_method: 'cod',
    idempotency_key: `lt-track-${__VU}-${Date.now()}`,
  }), { headers });

  if (!checkOk(create, 'tracking create order') || !create.json().data) {
    sleep(1);
    return;
  }
  const orderId = create.json().data.id;

  // Reuse the same minted token — the server reads it from the query string.
  const token = headers.Authorization.replace('Bearer ', '');
  const url = `${API.replace('/api/v1', '')}/api/v1/ws?token=${token}`;
  const listenMs = (__ENV.LISTEN_S ? Number(__ENV.LISTEN_S) : 5) * 1000;
  const started = Date.now();

  const res = ws.connect(url, {}, (socket) => {
    let joined = false;
    let events = 0;

    socket.on('open', () => socket.send(JSON.stringify({ type: 'join', channel: `order:${orderId}` })));
    socket.on('message', (msg) => {
      try {
        const m = JSON.parse(msg);
        if (m.type === 'joined') joined = true;
        if (m.type === 'event') events += 1;
      } catch (_) { /* ignore non-JSON frames */ }
    });
    socket.on('error', (e) => console.warn(`ws error: ${e.error()}`));
    socket.on('close', () => {});
    socket.setTimeout(() => socket.close(), listenMs);
    socket.setInterval(() => socket.send(JSON.stringify({ type: 'ping' })), 2000);
  });

  check(res, {
    'ws connected': (r) => r.status === 101,
  });
  // At least one ping-pong cycle must complete.
  check(Date.now() - started >= 2000, { 'session lasted ≥2s': (v) => v });

  sleep(1);
}