import http from "k6/http";
import { cfg } from "./config.js";
import { login, withAuthHeaders } from "./helpers/auth.js";
import { checkR, checkStatus } from "./helpers/assertions.js";

export const options = {
  vus: Number(__ENV.K6_VUS || 1),
  iterations: Number(__ENV.K6_ITERATIONS || 1),
};

export function setup() {
  const tokenA = login(cfg.tenantAUser, cfg.tenantAPass, "tenantA");
  const tokenB = login(cfg.tenantBUser, cfg.tenantBPass, "tenantB");
  return { tokenA, tokenB };
}

export default function (ctx) {
  const unauthorizedUrl = `${cfg.baseUrl}${cfg.protectedPath}`;
  const unauthorizedRes = http.get(unauthorizedUrl, {
    tags: { step: "unauthorized_should_401" },
  });
  checkStatus(unauthorizedRes, 401, "unauthorized access must be 401");

  const forbiddenUrl = `${cfg.baseUrl}${cfg.forbiddenPath}`;
  const forbiddenRes = http.get(forbiddenUrl, {
    headers: withAuthHeaders(ctx.tokenB),
    tags: { step: "forbidden_should_403" },
  });
  checkStatus(forbiddenRes, 403, "insufficient permission must be 403");

  const okUrl = `${cfg.baseUrl}${cfg.okPath}`;
  const okRes = http.get(okUrl, {
    headers: withAuthHeaders(ctx.tokenA),
    tags: { step: "authorized_should_200" },
  });
  checkStatus(okRes, 200, "authorized access must be 200");
  if (cfg.expectRWrapper) {
    checkR(okRes, "authorized response R<T>");
  }
}
