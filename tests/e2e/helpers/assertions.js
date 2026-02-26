import { check, fail } from "k6";

export function checkStatus(res, expected, label) {
  const ok = check(res, {
    [`${label}: status is ${expected}`]: (r) => r.status === expected,
  });

  if (!ok) {
    fail(`${label} expected=${expected} actual=${res.status} body=${res.body}`);
  }
}

export function checkStatusOneOf(res, allowedStatuses, label) {
  const ok = check(res, {
    [`${label}: status in [${allowedStatuses.join(",")}]`]: (r) => allowedStatuses.includes(r.status),
  });

  if (!ok) {
    fail(`${label} expected one of [${allowedStatuses.join(",")}] actual=${res.status} body=${res.body}`);
  }
}

export function checkR(res, label) {
  let payload;
  try {
    payload = res.json();
  } catch (err) {
    fail(`${label}: response is not JSON: ${String(err)} body=${res.body}`);
  }

  const ok = check(payload, {
    [`${label}: has code`]: (p) => p && Object.prototype.hasOwnProperty.call(p, "code"),
    [`${label}: has message`]: (p) => p && Object.prototype.hasOwnProperty.call(p, "message"),
    [`${label}: has data`]: (p) => p && Object.prototype.hasOwnProperty.call(p, "data"),
  });

  if (!ok) {
    fail(`${label}: R<T> contract violated payload=${JSON.stringify(payload)}`);
  }

  return payload;
}

export function expectCrossTenant404(res, actionLabel) {
  if (res.status !== 404) {
    fail(`tenant isolation violation for ${actionLabel}: expected=404 actual=${res.status} body=${res.body}`);
  }
}

export function checkJsonPath(obj, path, label) {
  const keys = path.split(".").filter(Boolean);
  let cur = obj;
  for (const key of keys) {
    if (cur == null || !(key in cur)) {
      fail(`${label}: missing json path ${path}`);
    }
    cur = cur[key];
  }
  return cur;
}
