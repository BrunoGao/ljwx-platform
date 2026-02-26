import http from "k6/http";
import { fail } from "k6";
import { cfg } from "../config.js";

function extractToken(payload) {
  const candidates = [
    payload?.data?.accessToken,
    payload?.data?.token,
    payload?.data?.jwt,
    payload?.accessToken,
    payload?.token,
    payload?.jwt,
  ];

  for (const candidate of candidates) {
    if (candidate && typeof candidate === "string") {
      return candidate;
    }
  }

  return "";
}

export function login(username, password, label = "user") {
  const url = `${cfg.baseUrl}${cfg.loginPath}`;
  const body = JSON.stringify({ username, password });
  const res = http.post(url, body, {
    headers: { "Content-Type": "application/json" },
    tags: { step: `login_${label}` },
  });

  if (res.status !== 200) {
    fail(`Login failed for ${label}: expected=200 actual=${res.status} url=${url} body=${res.body}`);
  }

  let payload;
  try {
    payload = res.json();
  } catch (err) {
    fail(`Login response is not JSON for ${label}: ${String(err)} body=${res.body}`);
  }

  const token = extractToken(payload);
  if (!token) {
    fail(`Login token missing for ${label}: response=${JSON.stringify(payload)}`);
  }

  return token;
}

export function withAuthHeaders(token) {
  return {
    "Content-Type": "application/json",
    Authorization: `Bearer ${token}`,
  };
}
