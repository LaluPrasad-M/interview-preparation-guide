# Runtime Recovery: Interceptor and Promise Sharing

> [!tldr]
> When 100 concurrent requests fail with 401, a single coordinated refresh prevents 100 calls to the provider. Promise sharing is the key.

Part of [[oauth-token-lifecycle]].

---

## The problem

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

This abstracts where runtime tokens live. Today it is an in memory `Map`, and in production it might be Redis or a shared distributed token layer.

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
