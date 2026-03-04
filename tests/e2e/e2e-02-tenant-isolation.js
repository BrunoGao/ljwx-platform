import http from "k6/http";
import { cfg } from "./config.js";
import { login, withAuthHeaders } from "./helpers/auth.js";
import { checkR, checkStatusOneOf, expectCrossTenant404 } from "./helpers/assertions.js";

export const options = {
  vus: Number(__ENV.K6_VUS || 1),
  iterations: Number(__ENV.K6_ITERATIONS || 1),
};

function getPathValue(root, path) {
  let cursor = root;
  for (const key of path) {
    if (cursor === null || cursor === undefined) {
      return undefined;
    }
    cursor = cursor[key];
  }
  return cursor;
}

function extractId(payload) {
  const candidates = [
    getPathValue(payload, ["data"]),
    getPathValue(payload, ["data", "id"]),
    getPathValue(payload, ["data", "record", "id"]),
    getPathValue(payload, ["data", 0, "id"]),
    getPathValue(payload, ["id"]),
  ];
  for (const candidate of candidates) {
    if ((typeof candidate === "string" || typeof candidate === "number") && candidate !== "") {
      return candidate;
    }
  }
  return null;
}

function containsId(node, expectedId) {
  if (node == null) {
    return false;
  }
  if (Array.isArray(node)) {
    return node.some((item) => containsId(item, expectedId));
  }
  if (typeof node === "object") {
    if (String(node.id) === String(expectedId)) {
      return true;
    }
    return Object.values(node).some((value) => containsId(value, expectedId));
  }
  return false;
}

function ensureEndpointExists(res, endpointLabel) {
  if (res.status === 404) {
    throw new Error(`Endpoint missing for ${endpointLabel}, expected implemented API, got 404. body=${res.body}`);
  }
}

export function setup() {
  const tokenA = login(cfg.tenantAUser, cfg.tenantAPass, "tenantA");
  const tokenB = login(cfg.tenantBUser, cfg.tenantBPass, "tenantB");

  const createUrl = `${cfg.baseUrl}${cfg.resourceBase}`;
  const resourceName = `test_e2e02_${cfg.runId}`;
  const createRes = http.post(
    createUrl,
    JSON.stringify({
      parentId: 0,
      name: resourceName,
      path: `/test/${resourceName}`,
      component: "TestComponent",
      menuType: 1,
      permission: `test:${resourceName}`,
      visible: 1,
    }),
    {
      headers: withAuthHeaders(tokenA),
      tags: { step: "tenantA_create_resource" },
    }
  );

  ensureEndpointExists(createRes, "create resource");
  checkStatusOneOf(createRes, [200, 201], "tenantA create resource");
  const createPayload = checkR(createRes, "tenantA create response R<T>");
  const id = extractId(createPayload);

  if (id == null) {
    throw new Error(`Create succeeded but no resource id found. payload=${JSON.stringify(createPayload)}`);
  }

  return { tokenA, tokenB, id };
}

export default function (ctx) {
  const id = ctx.id;

  const listUrl = `${cfg.baseUrl}${cfg.resourceListPath}`;
  const listRes = http.get(listUrl, {
    headers: withAuthHeaders(ctx.tokenB),
    tags: { step: "tenantB_list_should_not_contain_A_resource" },
  });
  ensureEndpointExists(listRes, "list resources");
  checkStatusOneOf(listRes, [200], "tenantB list resources");
  const listPayload = checkR(listRes, "tenantB list response R<T>");
  if (containsId(getPathValue(listPayload, ["data"]), id)) {
    throw new Error(`Tenant isolation violated: tenantB list contains tenantA resource id=${id}`);
  }

  const getRes = http.get(`${cfg.baseUrl}${cfg.resourceBase}/${id}`, {
    headers: withAuthHeaders(ctx.tokenB),
    tags: { step: "tenantB_get_tenantA_resource_should_404" },
  });
  expectCrossTenant404(getRes, "tenantB GET tenantA resource by id");

  const putRes = http.put(
    `${cfg.baseUrl}${cfg.resourceBase}/${id}`,
    JSON.stringify({ name: `hijack_${cfg.runId}` }),
    {
      headers: withAuthHeaders(ctx.tokenB),
      tags: { step: "tenantB_update_tenantA_resource_should_404" },
    }
  );
  expectCrossTenant404(putRes, "tenantB PUT tenantA resource by id");

  const delRes = http.del(`${cfg.baseUrl}${cfg.resourceBase}/${id}`, null, {
    headers: withAuthHeaders(ctx.tokenB),
    tags: { step: "tenantB_delete_tenantA_resource_should_404" },
  });
  expectCrossTenant404(delRes, "tenantB DELETE tenantA resource by id");

  const cleanupRes = http.del(`${cfg.baseUrl}${cfg.resourceBase}/${id}`, null, {
    headers: withAuthHeaders(ctx.tokenA),
    tags: { step: "tenantA_cleanup_delete" },
  });
  if (![200, 204, 404].includes(cleanupRes.status)) {
    throw new Error(`Cleanup delete unexpected status=${cleanupRes.status} body=${cleanupRes.body}`);
  }
}
