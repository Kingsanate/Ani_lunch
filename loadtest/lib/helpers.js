// Shared helpers for AniMeat load-test scripts.
//
// JWT strategy: the Go API validates Supabase-style JWTs with the shared
// HMAC secret (SUPABASE_JWT_SECRET). For load testing we mint equivalent
// HS256 tokens in-script — no Supabase dependency, no OTP round-trips.
//
// Role resolution is DB-driven (authz.ResolveActor): a user is a rider if a
// riders row exists, a vendor if a vendors row exists, admin via users flag,
// otherwise customer. The seed.sql creates matching rows for the fixed IDs
// used below.

import crypto from 'k6/crypto';
import encoding from 'k6/encoding';

// Match the development secret in backend/docker-compose.yml.
const JWT_SECRET = __ENV.JWT_SECRET || 'super-secret-jwt-key-for-local-dev-must-change';
// Match the API base URL (compose exposes 8080 on localhost).
export const BASE_URL = __ENV.BASE_URL || 'http://localhost:8080';
export const API = `${BASE_URL}/api/v1`;

// Fixed identities created by loadtest/seed.sql.
export const VENDOR_IDS = Array.from({ length: 8 }, (_, i) =>
  `00000000-0000-0000-0000-00000000000${i + 1}`);
export const RIDER_IDS = Array.from({ length: 24 }, (_, i) =>
  `10000000-0000-0000-0000-0000000000${String(i + 1).padStart(2, '0')}`);
export const CUSTOMER_IDS = Array.from({ length: 500 }, (_, i) =>
  `lt-customer-${i}`);

function b64url(input) {
  return encoding.b64encode(input, 'rawurl');
}

// mintToken issues an HS256 JWT with the platform's shared secret.
export function mintToken(sub, email, role, ttlSec = 3600) {
  const now = Math.floor(Date.now() / 1000);
  const header = b64url(JSON.stringify({ alg: 'HS256', typ: 'JWT' }));
  const payload = b64url(JSON.stringify({
    sub,
    email,
    role,
    iat: now,
    exp: now + ttlSec,
  }));
  const signature = b64url(
    crypto.createHMAC('sha256', JWT_SECRET).update(`${header}.${payload}`).digest('binary')
  );
  return `${header}.${payload}.${signature}`;
}

// authHeaders returns the JSON headers with a minted Bearer token.
export function authHeaders(sub, role) {
  return {
    'Content-Type': 'application/json',
    Authorization: `Bearer ${mintToken(sub, `${role}@animeat.test`, role)}`,
  };
}

// pick selects a pseudo-stable element from an array for a given VU.
export function pick(list, vu, seed = 0) {
  return list[(vu + seed) % list.length];
}

// checkOk is a thin wrapper: record success/failure and expose the body.
export function checkOk(res, name) {
  const ok = res.status >= 200 && res.status < 300;
  if (!ok) {
    console.warn(`${name} failed: HTTP ${res.status} ${res.body ? res.body.slice(0, 200) : ''}`);
  }
  return ok;
}