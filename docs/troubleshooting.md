# Troubleshooting

Common issues and solutions when using Kasumi.

## Table of Contents

- [Authentication Errors](#authentication-errors)
- [API Errors](#api-errors)
- [Connection Issues](#connection-issues)
- [JSON Parsing Errors](#json-parsing-errors)
- [Performance Issues](#performance-issues)
- [Output Problems](#output-problems)

---

## Authentication Errors

### Error: "invalid_auth"

**Symptoms:**
```
Failed to fetch conversations: invalid_auth
```

**Causes:**
- Token is expired
- Token is invalid or malformed
- Token doesn't have required permissions
- Wrong workspace token

**Solutions:**

1. **Verify token format:**
```bash
# OAuth tokens start with xoxp-
echo $SLACK_TOKEN | grep -o "^xoxp-"

# Cookie tokens start with xoxc-
echo $SLACK_TOKEN | grep -o "^xoxc-"
```

2. **Check for extra characters:**
```bash
# Remove whitespace and newlines
SLACK_TOKEN=$(echo "$SLACK_TOKEN" | tr -d '[:space:]')
```

3. **Regenerate token:**
   - Go to https://api.slack.com/apps
   - Select your app
   - Go to "OAuth & Permissions"
   - Reinstall to workspace
   - Copy new token

4. **Verify permissions:**
   Required scopes:
   - `channels:history`
   - `channels:read`
   - `groups:history`
   - `groups:read`
   - `im:history`
   - `im:read`
   - `mpim:history`
   - `mpim:read`
   - `search:read`

---

### Error: "token_revoked"

**Symptoms:**
```
Failed to fetch conversations: token_revoked
```

**Causes:**
- Token was manually revoked
- App was uninstalled
- Workspace admin revoked access

**Solutions:**

1. **Check app installation:**
   - Verify app is still installed in workspace
   - Check with workspace admin

2. **Generate new token:**
   - Reinstall app to workspace
   - Generate new OAuth token

3. **Use different authentication:**
   - Try cookie-based authentication instead
   - Use different workspace token

---

### Error: "Cookie-based authentication requires --cookie-d parameter"

**Symptoms:**
```
Cookie-based authentication (xoxc- token) requires --cookie-d parameter
```

**Causes:**
- Using `xoxc-` token without cookie value

**Solution:**

```bash
# Include --cookie-d parameter
./kasumi.pl \
    --token xoxc-your-token \
    --cookie-d "xoxd-your-cookie-value" \
    --keywords "search"
```

**How to get cookie value:**
1. Open browser developer tools (F12)
2. Go to Network tab
3. Visit Slack web app
4. Find request to api.slack.com
5. Look in request headers for: `Cookie: d=xoxd-...`
6. Copy the xoxd-... value

---

## API Errors

### Error: "rate_limited"

**Symptoms:**
```
Failed to fetch conversations: rate_limited
```

**Causes:**
- Too many API requests in short time
- Exceeded Slack's rate limits

**Solutions:**

1. **Wait and retry:**
```bash
# Wait 60 seconds and retry
sleep 60
./kasumi.pl --token xoxp-your-token --keywords "password"
```

2. **Use date ranges to reduce scope:**
```bash
# Limit to recent messages
./kasumi.pl --token xoxp-your-token \
    --keywords "password" \
    --from 2024-12-01
```

3. **Avoid threads if not needed:**
```bash
# Skip --threads flag for faster extraction
./kasumi.pl --token xoxp-your-token \
    --keywords "password"
```

**Note:** Kasumi has built-in 1-second delays between requests. Rate limiting usually occurs with very large workspaces.

---

### Error: "missing_scope"

**Symptoms:**
```
Failed to fetch conversations: missing_scope
```

**Causes:**
- Token doesn't have required OAuth scopes

**Solution:**

Add missing scopes to your Slack app:

1. Go to https://api.slack.com/apps
2. Select your app
3. Go to "OAuth & Permissions"
4. Add these scopes:
   - `channels:history`
   - `channels:read`
   - `groups:history`
   - `groups:read`
   - `im:history`
   - `im:read`
   - `mpim:history`
   - `mpim:read`
   - `search:read`
5. Reinstall app to workspace
6. Use new token

---

### Error: "not_in_channel"

**Symptoms:**
```
Warning: Failed to fetch history for C12345: not_in_channel
```

**Causes:**
- Bot/app not in specific channel
- Private channel without access

**Solutions:**

1. **For public channels:**
   - Invite the bot to the channel
   - `/invite @your-app-name`

2. **For private channels:**
   - Channel admin must invite the app
   - Or use user token instead of bot token

3. **Ignore the warning:**
   - Script will continue with accessible channels
   - This is expected behavior for restricted channels

---

## Connection Issues

### Error: "SSL certificate verify failed"

**Symptoms:**
```
HTTP error: 500 Can't connect to slack.com:443 (certificate verify failed)
```

**Causes:**
- Corporate SSL inspection
- Outdated CA certificates
- System certificate issues

**Solutions:**

1. **Update CA certificates:**

**Linux:**
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install ca-certificates

# CentOS/RHEL
sudo yum update ca-certificates
```

**macOS:**
```bash
# Update via brew
brew update
brew upgrade
```

2. **Install corporate CA certificate:**
```bash
# Linux
sudo cp corporate-ca.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates

# macOS
sudo security add-trusted-cert -d -r trustRoot \
    -k /Library/Keychains/System.keychain corporate-ca.crt
```

3. **Temporary workaround (testing only!):**
```bash
# WARNING: Insecure, use only for testing
./kasumi.pl --token xoxp-your-token \
    --keywords "test" \
    --no-verify-ssl
```

---

### Error: "Connection timeout"

**Symptoms:**
```
HTTP error: 500 Can't connect to slack.com:443 (Connection timed out)
```

**Causes:**
- Network connectivity issues
- Firewall blocking connection
- Proxy configuration needed

**Solutions:**

1. **Check internet connection:**
```bash
# Test connectivity
ping slack.com
curl -I https://slack.com
```

2. **Configure proxy (if needed):**
```bash
# Set proxy environment variables
export https_proxy=http://proxy.company.com:8080
export http_proxy=http://proxy.company.com:8080

./kasumi.pl --token xoxp-your-token --keywords "test"
```

3. **Check firewall:**
   - Ensure outbound HTTPS (443) is allowed
   - Whitelist slack.com domain
   - Contact network administrator

---

## JSON Parsing Errors

### Error: "JSON parsing error"

**Symptoms:**
```
JSON parsing error: malformed JSON string
Response preview: <!DOCTYPE html>...
```

**Causes:**
- Receiving HTML instead of JSON
- API endpoint changed
- Authentication redirecting to login page

**Solutions:**

1. **Verify authentication:**
```bash
# Test token validity
curl -H "Authorization: Bearer xoxp-your-token" \
    https://slack.com/api/auth.test
```

2. **Check token format:**
```bash
# Ensure no HTML in token
echo "$SLACK_TOKEN" | grep -q "<html>" && echo "Invalid token format"
```

3. **Try different authentication method:**
```bash
# Switch from cookie to OAuth or vice versa
./kasumi.pl --token xoxp-different-token --keywords "test"
```

---

### Error: "encountered object 'Fri Dec 5...', but neither allow_blessed..."

**Symptoms:**
```
encountered object 'Fri Dec 5 14:27:32 2025', but neither allow_blessed...
```

**Cause:**
- Fixed in current version

**Solution:**

Update to latest version - this was a bug that has been fixed.

---

## Performance Issues

### Issue: Extraction Very Slow

**Symptoms:**
- Taking hours to complete
- Appears hung

**Causes:**
- Large workspace
- Thread extraction enabled
- Rate limiting delays

**Solutions:**

1. **Check if it's actually working:**
```bash
# Watch output file grow
watch -n 5 'ls -lh slack_messages.json'

# Monitor progress in another terminal
tail -f /path/to/output.log
```

2. **Use date ranges:**
```bash
# Limit scope
./kasumi.pl --token xoxp-your-token \
    --download-all \
    --from 2024-12-01 \
    --size-limit 1024
```

3. **Disable threads:**
```bash
# Much faster without threads
./kasumi.pl --token xoxp-your-token \
    --download-all \
    --size-limit 1024
```

4. **Split into smaller chunks:**
```bash
# Extract monthly instead of yearly
for month in {01..12}; do
    ./kasumi.pl --token xoxp-your-token \
        --download-all \
        --from 2024-${month}-01 \
        --to 2024-${month}-31 \
        --output "2024_${month}.json"
done
```

---

### Issue: High Memory Usage

**Symptoms:**
- System running out of memory
- Script killed by system

**Causes:**
- Downloading too much data at once
- Size limit too high

**Solutions:**

1. **Reduce size limit:**
```bash
# Use smaller limit
./kasumi.pl --token xoxp-your-token \
    --download-all \
    --size-limit 512  # 512 MB instead of 1 GB
```

2. **Split downloads:**
```bash
# Download in smaller batches
./kasumi.pl --token xoxp-your-token \
    --download-all \
    --from 2024-01-01 \
    --to 2024-03-31 \
    --output Q1.json
```

3. **Monitor memory:**
```bash
# Watch memory usage
watch -n 2 'ps aux | grep kasumi.pl'
```

---

## Output Problems

### Issue: Empty Output File

**Symptoms:**
```json
{
  "extraction_date": "...",
  "total_messages": 0,
  "messages": []
}
```

**Causes:**
- No messages match criteria
- Date range has no messages
- Permissions issue

**Solutions:**

1. **Verify search criteria:**
```bash
# Try broader search
./kasumi.pl --token xoxp-your-token \
    --keywords "the"  # Very common word
```

2. **Check date range:**
```bash
# Remove date filters
./kasumi.pl --token xoxp-your-token \
    --keywords "password"
# No --from or --to
```

3. **Try download-all:**
```bash
# See if any messages are accessible
./kasumi.pl --token xoxp-your-token \
    --download-all \
    --size-limit 100
```

---

### Issue: File Permission Denied

**Symptoms:**
```
Cannot write to slack_messages.json: Permission denied
```

**Causes:**
- No write permission in directory
- File is read-only
- Disk full

**Solutions:**

1. **Check permissions:**
```bash
# Check directory permissions
ls -ld .

# Make writable
chmod u+w .
```

2. **Write to different location:**
```bash
# Use home directory
./kasumi.pl --token xoxp-your-token \
    --keywords "password" \
    --output ~/results.json
```

3. **Check disk space:**
```bash
# Check available space
df -h .

# Clean up if needed
rm old_files.json
```

---

### Issue: Output File Corrupted

**Symptoms:**
```
jq: parse error: Invalid numeric literal at line 1, column 10
```

**Causes:**
- Script interrupted during write
- Disk full during write
- System crash

**Solutions:**

1. **Try to recover:**
```bash
# Check if partially valid
head -100 slack_messages.json

# Try to extract valid parts
jq '.messages' slack_messages.json 2>/dev/null
```

2. **Re-extract:**
```bash
# Delete and re-run
rm slack_messages.json
./kasumi.pl --token xoxp-your-token --download-all
```

3. **Use atomic writes:**
```bash
# Write to temp file first
./kasumi.pl --token xoxp-your-token \
    --keywords "password" \
    --output temp.json

# Then move if successful
mv temp.json final.json
```

---

## General Debugging

### Enable Verbose Output

Add debug output to understand what's happening:

```bash
# Run with perl warnings
perl -w ./kasumi.pl --token xoxp-your-token --keywords "test"

# Show HTTP traffic (requires LWP::ConsoleLogger)
perl -MLWP::ConsoleLogger::Everywhere ./kasumi.pl \
    --token xoxp-your-token --keywords "test"
```

### Test Authentication

```bash
# Quick auth test
curl -H "Authorization: Bearer YOUR_TOKEN" \
    https://slack.com/api/auth.test | jq .
```

Expected response:
```json
{
  "ok": true,
  "url": "https://your-workspace.slack.com/",
  "team": "Your Workspace",
  "user": "your-user",
  "team_id": "T1234567890",
  "user_id": "U1234567890"
}
```

### Check Perl Dependencies

```bash
# Verify all modules are installed
perl -c ./kasumi.pl

# Test specific modules
perl -e 'use LWP::UserAgent; print "OK\n"'
perl -e 'use JSON; print "OK\n"'
perl -e 'use Time::Piece; print "OK\n"'
```

---

## Getting Help

If you're still having issues:

1. **Check the documentation:**
   - [Authentication](authentication.md)
   - [Search Modes](search-modes.md)
   - [Download Modes](download-modes.md)
   - [Advanced Options](advanced-options.md)

2. **Gather information:**
   ```bash
   # Perl version
   perl -v

   # OS information
   uname -a

   # Error messages
   ./kasumi.pl --token xoxp-your-token --keywords "test" 2>&1 | tee error.log
   ```

3. **Open an issue:**
   - Include error messages
   - Describe what you're trying to do
   - Mention OS and Perl version
   - Redact sensitive information (tokens, workspace names)

---

## Quick Fixes Checklist

- [ ] Token is valid and not expired
- [ ] Token has required OAuth scopes
- [ ] Internet connection is working
- [ ] Firewall allows HTTPS connections
- [ ] Sufficient disk space available
- [ ] Directory has write permissions
- [ ] Perl and required modules installed
- [ ] Using correct token format (xoxp- or xoxc-)
- [ ] Cookie value included for xoxc- tokens
- [ ] No extra whitespace in token
- [ ] Date format is YYYY-MM-DD
- [ ] Not hitting rate limits

---

## Next Steps

- [Examples](examples.md) - See working examples
- [Advanced Options](advanced-options.md) - Learn all options
- [Authentication](authentication.md) - Authentication guide
