// Search behaviour. The apps search client-side over the cached catalog, so
// the server-side equivalent is repeated filtered catalog reads (the ?category=
// filter) with varying filters — the pattern a server-authoritative search
// endpoint must absorb later.
//
// Run: k6 run -e VUS=100 loadtest/search.js

import http from 'k6/http';
import { check, sleep } from 'k6';
import { API, checkOk } from './lib/helpers.js';

export const options = {
  scenarios: {
    search: {
      executor: 'per-vu-iterations',
      vus: __ENV.VUS ? Number(__ENV.VUS) : 100,
      iterations: 25,
      maxDuration: '10m',
    },
  },
  thresholds: {
    http_req_failed: ['rate<0.01'],
    http_req_duration: ['p(95)<250', 'p(99)<500'],
  },
};

export default function () {
  // Alternate between scoped filter reads (category / availability).
  const query = __VU % 2 === 0
    ? `category=${(__VU % 8) + 1}`
    : 'category=1';

  const res = http.get(`${API}/catalog/items?${query}`);
  check(res, { 'search 200': (r) => r.status === 200 });
  checkOk(res, 'search/items');

  sleep(0.5 + Math.random());
}