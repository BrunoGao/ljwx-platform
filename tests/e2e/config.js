const now = Date.now();

function required(name, fallback = "") {
  const value = __ENV[name] || fallback;
  if (!value) {
    throw new Error(`Missing required env: ${name}`);
  }
  return value;
}

export const cfg = {
  runId: __ENV.RUN_ID || `${now}`,
  baseUrl: required("BASE_URL", "http://localhost:8080"),
  loginPath: __ENV.LOGIN_PATH || "/api/v1/auth/login",

  tenantAUser: required("TENANT_A_USER", "tenantA_admin"),
  tenantAPass: required("TENANT_A_PASS", "tenantA_admin_123"),
  tenantBUser: required("TENANT_B_USER", "tenantB_admin"),
  tenantBPass: required("TENANT_B_PASS", "tenantB_admin_123"),

  protectedPath: __ENV.PROTECTED_PATH || "/api/v1/menus/tree",
  forbiddenPath: __ENV.FORBIDDEN_PATH || "/api/v1/users/page",
  okPath: __ENV.OK_PATH || "/api/v1/menus/tree",
  expectRWrapper: (__ENV.EXPECT_R_WRAPPER || "true").toLowerCase() === "true",

  resourceBase: __ENV.RESOURCE_BASE || "/api/v1/menus",
  resourceListPath: __ENV.RESOURCE_LIST_PATH || "/api/v1/menus/list",
};
