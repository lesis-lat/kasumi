# Download Modes

Kasumi operates in two distinct modes: **Search Mode** and **Download Mode**. Understanding the difference helps you choose the right approach for your needs.

## Table of Contents

- [Search Mode vs Download Mode](#search-mode-vs-download-mode)
- [Search Mode (--keywords)](#search-mode---keywords)
- [Download Mode (--download-all)](#download-mode---download-all)
- [Size Limits](#size-limits)
- [Use Cases](#use-cases)
- [Performance Comparison](#performance-comparison)

---

## Search Mode vs Download Mode

### Quick Comparison

| Feature | Search Mode | Download Mode |
|---------|-------------|---------------|
| **Trigger** | `--keywords` | `--download-all` |
| **API Used** | `search.messages` | `conversations.history` |
| **Filtering** | Server-side | Local (none) |
| **Data Transfer** | Only matches | Everything |
| **Speed** | Fast | Slower |
| **Best For** | Targeted search | Offline analysis |
| **Size Limit** | No | Yes (default 1GB) |

### Visual Flow

**Search Mode:**
```
You → Slack Search API → Filtered Results → Download → Save
     (Server filters)        (Small data)
```

**Download Mode:**
```
You → List Conversations → Download All → Size Check → Save
                             (Large data)    (Stop at limit)
```

---

## Search Mode (--keywords)

Uses Slack's native search API to filter messages **before** downloading.

### When to Use

- ✅ You know what you're looking for
- ✅ You want fast, efficient searches
- ✅ Bandwidth is limited
- ✅ You need real-time results
- ✅ Searching for specific terms or patterns

### How It Works

1. Sends search query to Slack's `search.messages` API
2. Slack filters messages on their servers
3. Only matching messages are returned
4. Downloads only what matches
5. Saves filtered results

### Usage

```bash
# Basic keyword search
./kasumi.pl --token xoxp-your-token --keywords "password"

# Multiple keywords
./kasumi.pl --token xoxp-your-token --keywords "password secret token"

# With date range
./kasumi.pl --token xoxp-your-token \
    --keywords "password" \
    --from 2024-01-01 \
    --to 2024-12-31
```

### Example Output

```
[*] Using OAuth token authentication
[*] Download mode: Search mode (using Slack search API)
[*] Starting Slack message extraction...
[*] Keywords: password
[*] Date range: beginning to now
[*] Thread extraction: disabled

[*] Searching Slack messages for: 'password'
[+] Page 1: Found 100 results
[+] Page 2: Found 45 results
[+] Total search results: 145

[*] Saving results to slack_messages.json...
[+] Extraction complete! Total messages: 145
```

### Advantages

- **Fast**: Only downloads matching messages
- **Efficient**: Minimal bandwidth usage
- **Focused**: Gets exactly what you need
- **Scalable**: Works well on large workspaces

### Limitations

- Requires specific keywords
- Limited by Slack's search capabilities
- May miss messages with typos or variations
- Depends on Slack's search index

---

## Download Mode (--download-all)

Downloads **ALL** messages from **ALL** conversations for offline analysis.

### When to Use

- ✅ You need complete message history
- ✅ You want to search offline later
- ✅ You're doing comprehensive analysis
- ✅ You need data for compliance/legal reasons
- ✅ You want to use external tools (grep, jq, etc.)

### How It Works

1. Fetches list of all conversations (channels, DMs, groups)
2. Iterates through each conversation
3. Downloads entire history from each
4. Tracks total size during download
5. Stops when size limit is reached
6. Saves everything to JSON

### Basic Usage

```bash
# Download all with default 1GB limit
./kasumi.pl --token xoxp-your-token --download-all
```

### Example Output

```
[*] Using OAuth token authentication
[*] Download mode: Full extraction (all messages)
[*] Size limit: 1024 MB (1.00 GB)
[*] Starting Slack message extraction...
[*] Keywords: none
[*] Date range: beginning to now
[*] Thread extraction: disabled

[*] Fetching conversations list...
[+] Found 45 conversations

[*] Processing Public Channel: general
[*] Current size: 0.00 MB / 1024 MB
[+] Found 1,234 messages

[*] Processing Public Channel: random
[*] Current size: 15.42 MB / 1024 MB
[+] Found 3,456 messages

[*] Processing Private Channel: security
[*] Current size: 89.23 MB / 1024 MB
[+] Found 567 messages

...

[!] Size limit reached (1024 MB). Stopping extraction.

[*] Saving results to slack_messages.json...
[+] Extraction complete! Total messages: 45,678
```

### Advantages

- **Complete**: Gets everything available
- **Offline**: Use data without internet
- **Flexible**: Search with any tool you want
- **Comprehensive**: No missed messages
- **Repeatable**: Same dataset for multiple analyses

### Limitations

- Slower than search mode
- Uses more bandwidth
- Requires more storage
- May hit rate limits on large workspaces
- Respects size limits

---

## Size Limits

Size limits prevent downloading too much data and protect against runaway extractions.

### Default Limit

**1GB (1024 MB)** - Good balance for most use cases

### Custom Limits

```bash
# 500 MB limit
./kasumi.pl --token xoxp-your-token --download-all --size-limit 500

# 2 GB limit
./kasumi.pl --token xoxp-your-token --download-all --size-limit 2048

# 5 GB limit
./kasumi.pl --token xoxp-your-token --download-all --size-limit 5120

# 10 GB limit (be careful!)
./kasumi.pl --token xoxp-your-token --download-all --size-limit 10240
```

### How Size Tracking Works

1. Converts messages to JSON after each conversation
2. Calculates size in bytes
3. Converts to megabytes
4. Compares against limit
5. Stops if limit reached
6. Shows progress during download

### Size Estimation

Approximate message sizes:
- **Simple text message**: ~500 bytes
- **Message with reactions**: ~1 KB
- **Message with attachments**: ~2-5 KB
- **Thread with replies**: ~5-20 KB

**Example calculations:**
- 1,000 simple messages ≈ 0.5 MB
- 10,000 messages ≈ 5 MB
- 100,000 messages ≈ 50 MB
- 1,000,000 messages ≈ 500 MB

### Choosing the Right Limit

| Workspace Size | Recommended Limit | Use Case |
|----------------|-------------------|----------|
| Small (<10 channels) | 500 MB | Quick extraction |
| Medium (10-50 channels) | 1 GB (default) | Standard use |
| Large (50-200 channels) | 2-5 GB | Comprehensive |
| Enterprise (200+ channels) | 5-10 GB | Full archive |

---

## Use Cases

### Search Mode Use Cases

**Security Audit - Finding Credentials**
```bash
./kasumi.pl --token xoxp-your-token \
    --keywords "password api-key secret token" \
    --threads
```

**Compliance - Finding PII**
```bash
./kasumi.pl --token xoxp-your-token \
    --keywords "ssn social-security credit-card" \
    --from 2024-01-01
```

**Incident Response - Finding Breach Info**
```bash
./kasumi.pl --token xoxp-your-token \
    --keywords "hack breach unauthorized access" \
    --from 2024-12-01
```

**Legal Discovery - Specific Topics**
```bash
./kasumi.pl --token xoxp-your-token \
    --keywords "contract agreement from:@john" \
    --from 2024-01-01 \
    --to 2024-12-31
```

### Download Mode Use Cases

**Complete Backup**
```bash
./kasumi.pl --token xoxp-your-token \
    --download-all \
    --size-limit 10240 \
    --threads \
    --output backup_$(date +%Y%m%d).json
```

**Offline Analysis**
```bash
# Download everything
./kasumi.pl --token xoxp-your-token --download-all

# Then search offline with jq
jq '.messages[] | select(.text | contains("password"))' slack_messages.json

# Or use grep
grep -i "password" slack_messages.json
```

**Historical Archive**
```bash
# Archive 2024 messages
./kasumi.pl --token xoxp-your-token \
    --download-all \
    --from 2024-01-01 \
    --to 2024-12-31 \
    --output archive_2024.json
```

**Data Science / Analysis**
```bash
# Download for analysis with Python/R
./kasumi.pl --token xoxp-your-token \
    --download-all \
    --size-limit 5120

# Then analyze with Python
python analyze_messages.py slack_messages.json
```

---

## Performance Comparison

### Speed Test Example

**Workspace**: 100 channels, ~500,000 messages total

| Mode | Time | Data Downloaded | Messages Found |
|------|------|-----------------|----------------|
| Search (password) | 2 min | 5 MB | 145 messages |
| Download All (1GB) | 45 min | 1,024 MB | 234,567 messages |

### Bandwidth Usage

**Search Mode:**
```
Query: "password"
Results: 145 messages
Download: ~5 MB
Time: 2 minutes
```

**Download Mode:**
```
Conversations: 100
Messages: 234,567
Download: 1,024 MB (limit reached)
Time: 45 minutes
```

---

## Combining Modes

### Invalid Combinations

```bash
# ERROR: Can't use both
./kasumi.pl --token xoxp-your-token \
    --keywords "password" \
    --download-all

# Output: Error: --download-all and --keywords cannot be used together.
```

### Valid Combinations

```bash
# Download all with date filter
./kasumi.pl --token xoxp-your-token \
    --download-all \
    --from 2024-01-01

# Search with threads
./kasumi.pl --token xoxp-your-token \
    --keywords "password" \
    --threads

# Random search (uses search mode)
./kasumi.pl --token xoxp-your-token --random-search
```

---

## Best Practices

### For Search Mode
1. Use specific keywords for better results
2. Combine with date ranges to narrow scope
3. Use Slack search operators for precision
4. Enable threads only when needed

### For Download Mode
1. Set appropriate size limits
2. Use date ranges to limit scope
3. Save to descriptive filenames
4. Consider splitting large downloads
5. Monitor disk space

### General Tips
1. Test with small limits first
2. Use incremental backups (date ranges)
3. Compress JSON files after extraction
4. Document your extraction parameters
5. Respect rate limits (built-in delays)

---

## Next Steps

- [Advanced Options](advanced-options.md) - Date ranges, threads, SSL options
- [Examples](examples.md) - Real-world scenarios
- [Troubleshooting](troubleshooting.md) - Common issues and solutions
