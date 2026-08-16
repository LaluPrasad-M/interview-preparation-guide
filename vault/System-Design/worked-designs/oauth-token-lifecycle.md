# OAuth Token Lifecycle and Runtime Recovery

> [!tldr]
> Two layers, not one. A scheduler handles planned expiry, and an interceptor handles the unexpected 401. Promise sharing is what stops 100 concurrent failures becoming 100 refresh calls.

---

## The problem

A platform integrates with third party OAuth providers. Each tenant has a short lived access token and a long lived refresh token.

The requirements: avoid expired token failures, avoid refresh storms, refresh proactively, recover from unexpected 401s, handle concurrent requests safely, support multi pod scaling, and persist tokens durably.

---

## The architecture

```text
                +---------------------+
                |   Postgres DB       |
                | stores tokens       |
                +----------+----------+
                           |
                +----------v----------+
                | Background Scheduler|
                | proactive refresh   |
                +----------+----------+
                           |
                +----------v----------+
                | OAuth Provider      |
                +---------------------+
```

The runtime request flow:

```text
Application
     |
API Client
     |
Interceptor
     |
Provider API
     |
   401?
     |
Refresh Manager
     |
Retry Original Request
```

### Why both layers exist

**The proactive scheduler** solves planned token expiry. It gives smoother traffic, lower runtime failures, and avoids mass expiry spikes.

**Runtime recovery** solves unexpected invalidation: a revoked token, a stale pod cache, a delayed scheduler, or provider side invalidation.

---

## Part 1: proactive refresh

### The schema

```sql
CREATE TABLE oauth_tokens (
    tenant_id UUID PRIMARY KEY,
    access_token TEXT NOT NULL,
    refresh_token TEXT NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL
);
```

Memory only storage is insufficient, because pods restart, scaling happens, and tokens must survive crashes.

### Step 1: query expiring tokens

```js
async function getExpiringTokens(db) {
  const result = await db.query(`
      SELECT *
      FROM oauth_tokens
      WHERE expires_at <= NOW() + INTERVAL '15 minutes'
      ORDER BY expires_at ASC
      LIMIT 100
  `);

  return result.rows;
}

module.exports = { getExpiringTokens };
```

Every run fetches tokens expiring soon and refreshes them gradually, which smooths refresh traffic. Without the window and the `LIMIT`, 50,000 tokens could refresh simultaneously, creating auth storms and hitting provider rate limits.

### Step 2: refresh

```js
const axios = require("axios");

async function refreshAccessToken(tokenRecord) {
  const response = await axios.post(
    "https://oauth-provider.com/token",
    {
      grant_type: "refresh_token",
      refresh_token: tokenRecord.refresh_token
    }
  );

  return {
    accessToken: response.data.access_token,
    refreshToken: response.data.refresh_token,
    expiresIn: response.data.expires_in
  };
}

module.exports = { refreshAccessToken };
```

> [!warning] Refresh token rotation
> Some providers rotate the refresh token, meaning the old one becomes invalid after a refresh. Always persist the new refresh token if one is returned.

### Step 3: persist immediately

```js
async function updateToken(db, tenantId, tokenData) {
  const expiresAt = new Date(
    Date.now() + tokenData.expiresIn * 1000
  );

  await db.query(`
      UPDATE oauth_tokens
      SET
        access_token = $1,
        refresh_token = $2,
        expires_at = $3,
        updated_at = NOW()
      WHERE tenant_id = $4
  `, [
      tokenData.accessToken,
      tokenData.refreshToken,
      expiresAt,
      tenantId
  ]);
}

module.exports = { updateToken };
```

Crashes happen, pods restart, and stale tokens are dangerous. Durability matters.

### Step 4: the scheduler

```js
const cron = require("node-cron");
const { getExpiringTokens } = require("./token-repository");
const { refreshAccessToken } = require("./refresh-service");
const { updateToken } = require("./token-update");

cron.schedule("* * * * *", async () => {
  console.log("Running token refresh scheduler");

  const tokens = await getExpiringTokens(db);

  for (const token of tokens) {
    try {
      const refreshed = await refreshAccessToken(token);
      await updateToken(db, token.tenant_id, refreshed);
      console.log(`Refreshed tenant ${token.tenant_id}`);
    } catch (error) {
      console.error(`Failed refresh for tenant ${token.tenant_id}`);
    }
  }
});
```

Every minute it fetches expiring tokens, refreshes gradually and updates the database. That produces traffic smoothing instead of a refresh burst.

---

## Part 2: runtime recovery

### The problem

100 concurrent requests all fail with `401 Unauthorized`. Without coordination, that means 100 refresh calls to the provider. You need a single coordinated refresh.

### Step 5: the token store

```js
class TokenStore {
  constructor() {
    this.tokens = new Map();
  }

  get(tenantId) {
    return this.tokens.get(tenantId);
  }

  set(tenantId, tokenData) {
    this.tokens.set(tenantId, tokenData);
  }
}

module.exports = new TokenStore();
```

This abstracts where runtime tokens live. Today an in memory `Map`, in production Redis or a shared distributed token layer.

### Step 6: the refresh coordinator

```js
const axios = require("axios");
const tokenStore = require("./token-store");

class RefreshManager {
  constructor() {
    // tenantId -> refresh promise
    this.refreshPromises = new Map();
  }

  async refreshIfNeeded(tenantId, refreshToken) {
    // An existing refresh is already running
    if (this.refreshPromises.has(tenantId)) {
      console.log(`Waiting for existing refresh: ${tenantId}`);
      return this.refreshPromises.get(tenantId);
    }

    // A single refresh operation
    const refreshPromise = this.performRefresh(tenantId, refreshToken);

    this.refreshPromises.set(tenantId, refreshPromise);

    try {
      return await refreshPromise;
    } finally {
      this.refreshPromises.delete(tenantId);
    }
  }

  async performRefresh(tenantId, refreshToken) {
    console.log(`Refreshing ${tenantId}`);

    const response = await axios.post(
      "https://oauth-provider.com/token",
      {
        grant_type: "refresh_token",
        refresh_token: refreshToken
      }
    );

    const tokenData = {
      accessToken: response.data.access_token,
      refreshToken: response.data.refresh_token,
      expiresAt: Date.now() + response.data.expires_in * 1000
    };

    tokenStore.set(tenantId, tokenData);

    return tokenData;
  }
}

module.exports = new RefreshManager();
```

> [!tip] Promise sharing
> When 100 requests fail at once, only one refresh call goes to the provider. The other 99 await the same promise. This is one of the most useful Node concurrency patterns, and it is the same idea as singleflight or request coalescing.

### Step 7: the API client with interceptors

```js
const axios = require("axios");
const tokenStore = require("./token-store");
const refreshManager = require("./refresh-manager");

class ApiClient {
  constructor() {
    this.client = axios.create({
      baseURL: "https://provider-api.com"
    });

    this.setupInterceptors();
  }

  setupInterceptors() {
    // Request interceptor
    this.client.interceptors.request.use(
      async config => {
        const tenantId = config.tenantId;
        const tokenData = tokenStore.get(tenantId);

        config.headers.Authorization = `Bearer ${tokenData.accessToken}`;

        return config;
      }
    );

    // Response interceptor
    this.client.interceptors.response.use(
      response => response,
      async error => {
        const originalRequest = error.config;
        const status = error.response?.status;

        // Ignore non auth failures
        if (status !== 401) {
          throw error;
        }

        // Prevent an infinite retry loop
        if (originalRequest._retry) {
          throw error;
        }

        originalRequest._retry = true;

        const tenantId = originalRequest.tenantId;
        const tokenData = tokenStore.get(tenantId);

        // Coordinated refresh
        const refreshed = await refreshManager.refreshIfNeeded(
          tenantId,
          tokenData.refreshToken
        );

        // Update the request token
        originalRequest.headers.Authorization =
          `Bearer ${refreshed.accessToken}`;

        // Retry the original request
        return this.client(originalRequest);
      }
    );
  }

  async get(tenantId, url) {
    return this.client.get(url, { tenantId });
  }
}

module.exports = ApiClient;
```

**The request interceptor** runs before every outgoing request and injects the auth token automatically. Without it, every call injects the token by hand.

**The response interceptor** runs after every response, detects a 401 centrally, refreshes and retries. Without it, every call handles auth refresh, retry logic and concurrency itself.

### Step 8: what it looks like in use

```js
const ApiClient = require("./api-client");
const tokenStore = require("./token-store");

async function main() {
  tokenStore.set("tenant-1", {
    accessToken: "expired-token",
    refreshToken: "refresh-token",
    expiresAt: Date.now() - 1000
  });

  const client = new ApiClient();

  const requests = [];

  for (let i = 0; i < 5; i++) {
    requests.push(client.get("tenant-1", "/users"));
  }

  await Promise.all(requests);
}

main();
```

```text
Request
   |
Attach token
   |
Provider API
   |
  401?
   |
Single coordinated refresh
   |
Update token
   |
Retry original request
```

---

## The senior concepts

**Proactive plus reactive together.** Mature systems use both. The scheduler smooths traffic, runtime recovery handles unexpected failure.

**Promise sharing.** A `Map<tenantId, Promise>` prevents the refresh storm.

**Runtime recovery is the fallback.** The scheduler is the primary architecture, the interceptor is the safety net.

**Distributed reality.** This works inside one process. Across pods you need a Redis distributed lock, which is an important discussion point.

**Why interceptors exist.** They solve cross cutting concerns: auth injection, retries, tracing, logging, metrics and token recovery, all centralised.

---

## The production gotchas

**Refresh token rotation.** Always persist the new refresh token, because the provider may invalidate the old one.

**Infinite retry loops.** Without the `_retry` flag, a 401 retries forever.

**Multiple pods.** In memory promise coordination is not enough. You need a Redis lock.

**Scheduler delay.** Never rely only on proactive refresh, because runtime recovery is still required.

---

## The final mental model

| Layer | Responsibility |
| --- | --- |
| Postgres | durable token storage |
| Scheduler | planned refresh |
| Runtime API client | outgoing API handling |
| Interceptors | centralised request and response auth logic |
| Refresh manager | preventing the refresh stampede |
| Token store | runtime token access |
| Redis | distributed locking, once you are multi pod |
