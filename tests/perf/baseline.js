import http from "k6/http";
import { sleep, check } from "k6";
import { Trend } from "k6/metrics";
import { cfg } from "../e2e/config.js";
import { login, withAuthHeaders } from "../e2e/helpers/auth.js";

export const options = {
  vus: Number(__ENV.K6_VUS || 5),
  duration: __ENV.K6_DURATION || "30s",
  thresholds: {},
};

const latencyTrend = new Trend("baseline_endpoint_latency");

const defaultEndpoints = [
  "/actuator/health",
  "/api/v1/menus/tree",
  "/api/v1/notices/page",
  "/api/v1/operation-logs/page",
  "/api/v1/login-logs/page",
  "/api/v1/data-change-logs/page",
];

const endpoints = (__ENV.PERF_ENDPOINTS || defaultEndpoints.join(","))
  .split(",")
  .map((s) => s.trim())
  .filter(Boolean);

export function setup() {
  const tokenA = login(cfg.tenantAUser, cfg.tenantAPass, "tenantA_perf");
  return { tokenA };
}

export default function (ctx) {
  for (const path of endpoints) {
    const isPublic = path.startsWith("/actuator/") || path.startsWith("/health");
    const res = http.get(`${cfg.baseUrl}${path}`, {
      headers: isPublic ? {} : withAuthHeaders(ctx.tokenA),
      tags: { endpoint: path, gate: "R11" },
    });

    latencyTrend.add(res.timings.duration, { endpoint: path });

    check(res, {
      [`${path} status < 500`]: (r) => r.status < 500,
    });
  }

  sleep(1);
}
