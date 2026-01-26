# Advanced Options

Kasumi provides several advanced options to fine-tune your message extraction.

## Table of Contents

- [Date Filtering](#date-filtering)
- [Thread Extraction](#thread-extraction)
- [Output Options](#output-options)
- [SSL Options](#ssl-options)
- [Combining Options](#combining-options)

---

## Date Filtering

Filter messages by date range to focus on specific time periods.

### Options

- `--from <DATE>`: Extract messages from this date onwards
- `--to <DATE>`: Extract messages until this date

### Date Format

**Required format**: `YYYY-MM-DD`

Examples:
- `2024-01-01` ✅
- `2024-12-31` ✅
- `01-01-2024` ❌ (wrong format)
- `2024/01/01` ❌ (wrong separator)

### Basic Usage

```bash
# Messages from a specific date onwards
./kasumi.pl --token xoxp-your-token \
    --keywords "password" \
    --from 2024-01-01

# Messages until a specific date
./kasumi.pl --token xoxp-your-token \
    --keywords "password" \
    --to 2024-12-31

# Messages within a date range
./kasumi.pl --token xoxp-your-token \
    --keywords "password" \
    --from 2024-01-01 \
    --to 2024-12-31
```

### Use Cases

**Monthly Extraction**
```bash
# Extract January 2024
./kasumi.pl --token xoxp-your-token \
    --download-all \
    --from 2024-01-01 \
    --to 2024-01-31 \
    --output january_2024.json
```

**Recent Messages**
```bash
# Last 7 days
./kasumi.pl --token xoxp-your-token \
    --keywords "important" \
    --from $(date -d '7 days ago' +%Y-%m-%d)

# Last 30 days
./kasumi.pl --token xoxp-your-token \
    --keywords "urgent" \
    --from $(date -d '30 days ago' +%Y-%m-%d)
```

**Incident Investigation**
```bash
# Messages during specific incident window
./kasumi.pl --token xoxp-your-token \
    --keywords "error outage down" \
    --from 2024-12-01 \
    --to 2024-12-02
```

**Compliance Periods**
```bash
# Quarterly archive
./kasumi.pl --token xoxp-your-token \
    --download-all \
    --from 2024-10-01 \
    --to 2024-12-31 \
    --output Q4_2024.json
```

**Historical Analysis**
```bash
# Compare year over year
./kasumi.pl --token xoxp-your-token \
    --keywords "revenue" \
    --from 2023-01-01 \
    --to 2023-12-31 \
    --output 2023.json

./kasumi.pl --token xoxp-your-token \
    --keywords "revenue" \
    --from 2024-01-01 \
    --to 2024-12-31 \
    --output 2024.json
```

### Important Notes

- Dates are in **workspace timezone**
- `--from` is inclusive (includes messages from that date)
- `--to` is inclusive (includes messages up to end of that date)
- Works with both search and download modes
- No date range = all available messages

---

## Thread Extraction

Extract thread replies along with parent messages.

### Option

- `--threads`: Enable thread extraction

### How It Works

1. Extracts parent messages first
2. For each message with replies:
   - Calls `conversations.replies` API
   - Downloads all replies in thread
   - Attaches to parent message
3. Adds 1-second delay between thread fetches (rate limiting)

### Basic Usage

```bash
# Search with threads
./kasumi.pl --token xoxp-your-token \
    --keywords "password" \
    --threads

# Download all with threads
./kasumi.pl --token xoxp-your-token \
    --download-all \
    --threads
```

### Output Structure

**Without threads:**
```json
{
  "text": "Anyone know the DB password?",
  "user": "U123456",
  "ts": "1701788400.123456",
  "reply_count": 3
}
```

**With threads:**
```json
{
  "text": "Anyone know the DB password?",
  "user": "U123456",
  "ts": "1701788400.123456",
  "reply_count": 3,
  "thread_replies": [
    {
      "text": "It's in the vault",
      "user": "U789012",
      "ts": "1701788460.123457"
    },
    {
      "text": "Thanks!",
      "user": "U123456",
      "ts": "1701788520.123458"
    }
  ]
}
```

### Performance Impact

**Without threads:**
```
Time: 2 minutes
API calls: 150
```

**With threads:**
```
Time: 15 minutes (7.5x slower)
API calls: 450 (3x more)
Rate limiting: 1 sec per thread
```

### Use Cases

**Security Audit**
```bash
# Find passwords and their context
./kasumi.pl --token xoxp-your-token \
    --keywords "password" \
    --threads
```

**Complete Context**
```bash
# Get full conversation threads
./kasumi.pl --token xoxp-your-token \
    --keywords "incident" \
    --threads
```

**Decision Tracking**
```bash
# Track decision discussions
./kasumi.pl --token xoxp-your-token \
    --keywords "approve decision" \
    --threads
```

### Best Practices

1. **Only use when needed** - Significantly slower
2. **Combine with keywords** - Reduce number of threads
3. **Use date ranges** - Limit scope
4. **Be patient** - 1 sec delay per thread (rate limiting)
5. **Check file size** - Threads increase output size

### Thread Statistics

Output includes thread statistics:
```json
{
  "extraction_date": "Fri Dec 5 14:27:32 2025",
  "total_messages": 145,
  "total_thread_replies": 387,
  "messages": [...]
}
```

---

## Output Options

Control where and how results are saved.

### Option

- `--output <FILE>`: Output JSON file (default: `slack_messages.json`)

### Basic Usage

```bash
# Custom filename
./kasumi.pl --token xoxp-your-token \
    --keywords "password" \
    --output findings.json

# Date-based filename
./kasumi.pl --token xoxp-your-token \
    --download-all \
    --output backup_$(date +%Y%m%d).json

# Descriptive filename
./kasumi.pl --token xoxp-your-token \
    --keywords "password" \
    --from 2024-01-01 \
    --output passwords_jan2024.json
```

### Organization Strategies

**By Date**
```bash
./kasumi.pl --token xoxp-your-token \
    --download-all \
    --output "archives/$(date +%Y)/$(date +%m)/messages.json"
```

**By Search Term**
```bash
for term in password secret token api-key; do
    ./kasumi.pl --token xoxp-your-token \
        --keywords "$term" \
        --output "results/${term}.json"
done
```

**By Channel**
```bash
./kasumi.pl --token xoxp-your-token \
    --keywords "in:#security" \
    --output "channels/security.json"
```

**Timestamped**
```bash
./kasumi.pl --token xoxp-your-token \
    --random-search \
    --output "random_$(date +%Y%m%d_%H%M%S).json"
```

### File Management

**Compression**
```bash
# Extract then compress
./kasumi.pl --token xoxp-your-token --download-all
gzip slack_messages.json
# Creates: slack_messages.json.gz (much smaller)

# Use compressed file
zcat slack_messages.json.gz | jq '.messages[] | .text'
```

**Splitting Large Files**
```bash
# Extract in chunks by date
for month in {01..12}; do
    ./kasumi.pl --token xoxp-your-token \
        --download-all \
        --from 2024-${month}-01 \
        --to 2024-${month}-31 \
        --output "2024_month_${month}.json"
done
```

---

## SSL Options

Configure SSL certificate verification.

### Option

- `--no-verify-ssl`: Disable SSL certificate verification

### ⚠️ WARNING

**ONLY use this for testing!**
- Disables SSL/TLS certificate verification
- Makes connections vulnerable to MITM attacks
- Should NEVER be used in production
- Only for corporate networks with SSL inspection

### Usage

```bash
# For testing environments only
./kasumi.pl --token xoxp-your-token \
    --keywords "test" \
    --no-verify-ssl
```

### When You Might Need This

1. **Corporate SSL Inspection**
   - Company proxies that inspect SSL traffic
   - Self-signed certificates on corporate network

2. **Testing/Development**
   - Local Slack mock servers
   - Development environments

3. **Troubleshooting**
   - Diagnosing SSL-related issues
   - Temporary workaround while fixing certificates

### Warning Message

When used, you'll see:
```
WARNING: SSL certificate verification is disabled. Use only for testing!
```

### Proper Solution

Instead of disabling verification:

1. **Install Corporate CA Certificate**
```bash
# Linux
sudo cp corporate-ca.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates

# macOS
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain corporate-ca.crt
```

2. **Use Environment Variables**
```bash
export PERL_LWP_SSL_CA_FILE=/path/to/ca-bundle.crt
./kasumi.pl --token xoxp-your-token --keywords "test"
```

3. **Fix Network Configuration**
   - Configure proxy properly
   - Update system certificates
   - Contact IT department

---

## Combining Options

### Common Combinations

**Complete Security Audit**
```bash
./kasumi.pl --token xoxp-your-token \
    --keywords "password secret api-key token" \
    --threads \
    --from 2024-01-01 \
    --output security_audit_2024.json
```

**Monthly Archive with Threads**
```bash
./kasumi.pl --token xoxp-your-token \
    --download-all \
    --threads \
    --from 2024-11-01 \
    --to 2024-11-30 \
    --size-limit 2048 \
    --output november_2024_archive.json
```

**Recent Incident Investigation**
```bash
./kasumi.pl --token xoxp-your-token \
    --keywords "error exception crash outage" \
    --threads \
    --from $(date -d '7 days ago' +%Y-%m-%d) \
    --output incident_$(date +%Y%m%d).json
```

**Compliance Extraction**
```bash
./kasumi.pl --token xoxp-your-token \
    --download-all \
    --threads \
    --from 2024-01-01 \
    --to 2024-12-31 \
    --size-limit 5120 \
    --output compliance_2024.json
```

### Complex Workflows

**Daily Monitoring**
```bash
#!/bin/bash
# daily_check.sh

DATE=$(date +%Y-%m-%d)
YESTERDAY=$(date -d 'yesterday' +%Y-%m-%d)

./kasumi.pl --token "$SLACK_TOKEN" \
    --keywords "password secret credential" \
    --from "$YESTERDAY" \
    --to "$DATE" \
    --threads \
    --output "daily/${DATE}_security.json"

# Check if any results found
if [ $(jq '.total_messages' "daily/${DATE}_security.json") -gt 0 ]; then
    echo "WARNING: Found sensitive information on $DATE"
    # Send alert
fi
```

**Multi-Term Search**
```bash
#!/bin/bash
# multi_search.sh

TERMS=("password" "api-key" "secret" "token" "credential")
DATE=$(date +%Y%m%d)

for term in "${TERMS[@]}"; do
    ./kasumi.pl --token "$SLACK_TOKEN" \
        --keywords "$term" \
        --threads \
        --from 2024-01-01 \
        --output "results/${DATE}_${term}.json"

    echo "Found $(jq '.total_messages' results/${DATE}_${term}.json) messages for: $term"
done
```

**Incremental Backup**
```bash
#!/bin/bash
# incremental_backup.sh

YEAR=$(date +%Y)
MONTH=$(date +%m)

./kasumi.pl --token "$SLACK_TOKEN" \
    --download-all \
    --threads \
    --from "${YEAR}-${MONTH}-01" \
    --size-limit 2048 \
    --output "backups/${YEAR}/${MONTH}/messages.json"

# Compress
gzip "backups/${YEAR}/${MONTH}/messages.json"
```

---

## Performance Tuning

### Optimize for Speed

```bash
# Fast keyword search (no threads, no date filter)
./kasumi.pl --token xoxp-your-token --keywords "password"
```

### Optimize for Completeness

```bash
# Get everything (slower but complete)
./kasumi.pl --token xoxp-your-token \
    --download-all \
    --threads \
    --size-limit 10240
```

### Balanced Approach

```bash
# Good balance of speed and completeness
./kasumi.pl --token xoxp-your-token \
    --keywords "password" \
    --threads \
    --from 2024-01-01
```

---

## Next Steps

- [Examples](examples.md) - Real-world usage scenarios
- [Troubleshooting](troubleshooting.md) - Common issues and solutions
- [Search Modes](search-modes.md) - Keyword and random search
- [Download Modes](download-modes.md) - Search vs. full download
