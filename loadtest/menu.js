// Menu browsing — deep menu detail reads: full item catalog per category,
// plus lunch meal-product listings. Heavier payloads than browse.
//
// Run: k6 run -e VUS=300 loadtest/menu.js

import http from 'k6/http';
import { check, sleep } from 'k6';
import { API, checkOk } from './lib/helpers.js';

export const options = {
  scenarios: {
    menu: {
      executor: 'per-vu-iterations',
      vus: __ENV.VUS ? Number(__ENV.VUS) : 300,
      iterations: 20,
      maxDuration: '10m',
    },
  },
  thresholds: {
    http_req_failed: ['rate<0.01'],
    http_req_duration: ['p(95)<300', 'p(99)<600'],
  },
};

export default function () {
  const category = String((__VU % 8) + 1);

  // Full menu for the category + daily deals (meal_products come through deals).
  const items = http.get(`${API}/catalog/items?category=${category}`);
  const deals = http.get(`${API}/catalog/deals`);

  check(items, { 'menu items 200': (r) => r.status === 200 });
  check(deals, { 'menu deals 200': (r) => r.status === 200 });
  checkOk(items, 'menu/items');
  checkOk(deals, 'menu/deals');

  sleep(1 + Math.random() * 2);
}