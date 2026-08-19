// Browsing profile — the dominant mobile traffic: splash → home → catalog.
// Public endpoints, no auth. Simulates a user opening the app and
// scrolling the home feed (categories + deals + hot items).
//
// Run: k6 run -e VUS=400 loadtest/browse.js

import http from 'k6/http';
import { check, sleep } from 'k6';
import { API, checkOk } from './lib/helpers.js';

export const options = {
  scenarios: {
    browse: {
      executor: 'per-vu-iterations',
      vus: __ENV.VUS ? Number(__ENV.VUS) : 400,
      iterations: 30,
      maxDuration: '10m',
    },
  },
  thresholds: {
    http_req_failed: ['rate<0.01'],
    http_req_duration: ['p(95)<250', 'p(99)<500'],
  },
};

export default function () {
  // Category filter lets the backend exercise its category path.
  const category = String((__VU % 8) + 1);

  const menus = http.get(`${API}/catalog/menus`);
  check(menus, { 'menus 200': (r) => r.status === 200 });

  const deals = http.get(`${API}/catalog/deals`);
  check(deals, { 'deals 200': (r) => r.status === 200 });

  const items = http.get(`${API}/catalog/items?category=${category}`);
  check(items, { 'items 200': (r) => r.status === 200 });

  checkOk(items, 'catalog/items');
  sleep(2 + Math.random() * 4); // human scroll pause
}