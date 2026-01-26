# Authentication

Kasumi supports two types of Slack authentication methods. The tool automatically detects which method to use based on your token prefix.

## Table of Contents

- [OAuth Token Authentication (xoxp-)](#oauth-token-authentication-xoxp)
- [Cookie-Based Authentication (xoxc-)](#cookie-based-authentication-xoxc)
- [How to Get Your Tokens](#how-to-get-your-tokens)
- [Security Best Practices](#security-best-practices)

---

## OAuth Token Authentication (xoxp-)

OAuth tokens are the recommended and simplest authentication method.

### Token Format
```
xoxp-1234567890-1234567890-1234567890-abc123def456...
```

### Usage
```bash
./kasumi.pl --token xoxp-your-token-here --keywords "search term"
```

### Advantages
- Simpler to use (only one parameter needed)
- More stable authentication
- Easier to obtain from Slack App settings

### When to Use
- For personal workspaces
- When you have API access
- For automated scripts

---

## Cookie-Based Authentication (xoxc-)

Cookie-based authentication requires both a token and a cookie value.

### Token Format
```
xoxc-1234567890-1234567890-1234567890-abc123def456...
```

### Cookie Format (d parameter)
```
xoxd-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX...
```

### Usage
```bash
./kasumi.pl \
    --token xoxc-your-token-here \
    --cookie-d "xoxd-your-cookie-value-here" \
    --keywords "search term"
```

### When Required
- When using tokens that start with `xoxc-`
- For certain enterprise workspaces
- When OAuth tokens are not available

### Important Notes
- The `--cookie-d` parameter is **required** when using `xoxc-` tokens
- Cookie values are URL-encoded
- Cookies may expire more frequently than OAuth tokens

---

## How to Get Your Tokens

### Method 1: Browser Developer Tools (Cookie Method)

1. **Open Slack in your browser** and log in to your workspace

2. **Open Developer Tools**:
   - Chrome/Edge: `F12` or `Ctrl+Shift+I` (Windows) / `Cmd+Option+I` (Mac)
   - Firefox: `F12` or `Ctrl+Shift+K`

3. **Go to the Network tab**

4. **Filter by XHR or Fetch requests**

5. **Look for requests to `api.slack.com`**

6. **Find the Request Headers**:
   - Look for `Authorization: Bearer xoxc-...` → This is your token
   - Look for `Cookie: d=xoxd-...` → This is your cookie-d value

7. **Copy both values**

### Method 2: Slack App Configuration (OAuth Method)

1. **Go to**: https://api.slack.com/apps

2. **Create a new app** or select an existing one

3. **Go to "OAuth & Permissions"**

4. **Add the following scopes**:
   - `channels:history`
   - `channels:read`
   - `groups:history`
   - `groups:read`
   - `im:history`
   - `im:read`
   - `mpim:history`
   - `mpim:read`
   - `search:read`
   - `users:read`

5. **Install app to workspace**

6. **Copy the "User OAuth Token"** (starts with `xoxp-`)

### Method 3: Workspace App Tokens

Some workspaces provide API tokens directly:

1. Go to your workspace settings
2. Navigate to "Customize" → "Configure Apps"
3. Look for API tokens or custom integrations
4. Generate or copy existing tokens

---

## Security Best Practices

### DO:
- ✅ Store tokens in environment variables
- ✅ Use `.env` files (and add them to `.gitignore`)
- ✅ Rotate tokens regularly
- ✅ Use read-only tokens when possible
- ✅ Revoke tokens immediately if compromised

### DON'T:
- ❌ Commit tokens to version control
- ❌ Share tokens in chat or email
- ❌ Use tokens on untrusted systems
- ❌ Leave tokens in shell history
- ❌ Store tokens in plaintext files

### Using Environment Variables

#### Bash/Zsh
```bash
export SLACK_TOKEN="xoxp-your-token"
export SLACK_COOKIE="xoxd-your-cookie"

./kasumi.pl --token "$SLACK_TOKEN" --keywords "password"
```

#### PowerShell
```powershell
$env:SLACK_TOKEN = "xoxp-your-token"
$env:SLACK_COOKIE = "xoxd-your-cookie"

./kasumi.pl --token $env:SLACK_TOKEN --keywords "password"
```

### Using .env Files

Create a `.env` file:
```bash
SLACK_TOKEN=xoxp-your-token-here
SLACK_COOKIE=xoxd-your-cookie-here
```

Load it before running:
```bash
source .env
./kasumi.pl --token "$SLACK_TOKEN" --keywords "password"
```

**Important**: Add `.env` to your `.gitignore`!

---

## Troubleshooting Authentication

### Error: "invalid_auth"
- Token is expired or invalid
- Try regenerating your token
- Check if you're using the correct workspace

### Error: "Cookie-based authentication requires --cookie-d parameter"
- You're using a `xoxc-` token without the cookie
- Add `--cookie-d` parameter with your cookie value

### Error: "Failed to fetch conversations: token_revoked"
- Token has been revoked
- Generate a new token
- Check workspace permissions

### Error: "not_authed"
- Token is missing or malformed
- Verify token format (should start with `xoxp-` or `xoxc-`)
- Check for extra spaces or line breaks

---

## Verifying Your Authentication

Test your authentication with a simple command:

```bash
# For OAuth tokens
./kasumi.pl --token xoxp-your-token --help

# For cookie tokens
./kasumi.pl \
    --token xoxc-your-token \
    --cookie-d "your-cookie" \
    --help
```

If authentication is working, you should see:
```
[*] Using OAuth token authentication
```
or
```
[*] Using cookie-based authentication
```

---

## Next Steps

Once you have authentication working, check out:
- [Search Modes](search-modes.md) - Learn about keyword and random search
- [Download Modes](download-modes.md) - Full download vs. search
- [Examples](examples.md) - Real-world usage examples
