# Proactive OAuth Refresh Scheduler

> [!tldr]
> Query expiring tokens gradually every minute and refresh before they fail, smoothing the refresh traffic.

Part of [[oauth-token-lifecycle]].

---

## The schema

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
