# Search Modes

Kasumi offers multiple search modes to help you find messages efficiently. Each mode has its own use cases and advantages.

## Table of Contents

- [Keyword Search](#keyword-search)
- [Random Search](#random-search)
- [Custom Wordlists](#custom-wordlists)
- [Comparison Table](#comparison-table)

---

## Keyword Search

The most direct and efficient way to search for specific content in Slack messages.

### How It Works

Keyword search uses Slack's native `search.messages` API to filter messages **server-side** before downloading. This means:
- ✅ Only matching messages are downloaded
- ✅ Much faster than downloading everything
- ✅ Reduces bandwidth usage
- ✅ More efficient for targeted searches

### Basic Usage

```bash
./kasumi.pl --token xoxp-your-token --keywords "password"
```

### Multiple Keywords

You can search for multiple keywords (space-separated):

```bash
./kasumi.pl --token xoxp-your-token --keywords "password senha secret"
```

**Note**: Slack's search API treats multiple keywords as OR (any match), not AND (all matches).

### Search Operators

You can use Slack's search operators:

```bash
# Search in specific channel
./kasumi.pl --token xoxp-your-token --keywords "password in:#security"

# Search from specific user
./kasumi.pl --token xoxp-your-token --keywords "password from:@john"

# Search with exact phrase
./kasumi.pl --token xoxp-your-token --keywords '"database password"'

# Search excluding terms
./kasumi.pl --token xoxp-your-token --keywords "password -test"
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
[+] Page 2: Found 85 results
[+] Total search results: 185

[*] Saving results to slack_messages.json...
[+] Extraction complete! Total messages: 185
```

---

## Random Search

Automatically search using random keywords - useful for reconnaissance, testing, or discovering unexpected sensitive information.

### How It Works

Random search mode:
1. Selects a random keyword from a predefined list
2. Performs a search using that keyword
3. Uses Slack's search API (same as keyword search)

### Basic Usage

```bash
./kasumi.pl --token xoxp-your-token --random-search
```

### Example Output

```
[*] Using OAuth token authentication
[*] Download mode: Search mode (using Slack search API)
[*] Random search mode enabled
[*] Using random keyword: bitcoin

[*] Starting Slack message extraction...
[*] Keywords: bitcoin
[*] Date range: beginning to now
[*] Thread extraction: disabled

[*] Searching Slack messages for: 'bitcoin'
[+] Page 1: Found 42 results
[+] Total search results: 42
```

### Use Cases

**Security Testing**
```bash
# Run multiple random searches to discover sensitive info
for i in {1..10}; do
    ./kasumi.pl --token xoxp-your-token --random-search \
        --output "results_$i.json"
    sleep 5
done
```

**Reconnaissance**
```bash
# Discover what people are talking about
./kasumi.pl --token xoxp-your-token --random-search --threads
```

**Testing/Monitoring**
```bash
# Regular random searches to monitor workspace content
./kasumi.pl --token xoxp-your-token --random-search \
    --from $(date +%Y-%m-%d)
```

---

## Custom Wordlists

Provide your own list of keywords for random searches.

### Default Wordlist

Kasumi includes a default `wordlist.txt` with 400+ keywords organized by category:
- Technology terms (server, database, api, etc.)
- Security terms (password, secret, token, etc.)
- Business terms (budget, contract, invoice, etc.)
- Common words (important, urgent, help, etc.)

### Using Default Wordlist

If `wordlist.txt` exists in the current directory, it's automatically used:

```bash
./kasumi.pl --token xoxp-your-token --random-search
```

Output:
```
[*] Loading keywords from: wordlist.txt
[+] Loaded 428 keywords from wordlist
[*] Random search mode enabled
[*] Using random keyword: cryptocurrency
```

### Creating Custom Wordlist

Create a text file with one keyword per line:

**my_wordlist.txt**
```
password
senha
secret
api-key
credentials
token
database
backup
confidential
```

### Using Custom Wordlist

```bash
./kasumi.pl --token xoxp-your-token \
    --random-search \
    --wordlist my_wordlist.txt
```

### Wordlist Format

**Supported Features:**
- One keyword per line
- Comments (lines starting with `#`)
- Empty lines (ignored)
- Leading/trailing whitespace (automatically trimmed)

**Example:**
```
# Security-related keywords
password
senha
secret
api-key

# Financial terms
budget
invoice
payment

# Development terms
database
server
production
```

### Advanced Wordlist Usage

**Domain-Specific Wordlist**
```bash
# Create wordlist for financial data
cat > finance_words.txt << 'EOF'
invoice
payment
salary
budget
revenue
profit
loss
bank
account
credit
debit
wire
transfer
EOF

./kasumi.pl --token xoxp-your-token \
    --random-search \
    --wordlist finance_words.txt
```

**Multi-Language Wordlist**
```bash
# Search for passwords in multiple languages
cat > passwords_multilang.txt << 'EOF'
password
senha
contraseña
mot-de-passe
passwort
parola
hasło
EOF

./kasumi.pl --token xoxp-your-token \
    --random-search \
    --wordlist passwords_multilang.txt
```

### Fallback Behavior

If wordlist file is not found:
1. Tries to load `wordlist.txt` from current directory
2. Falls back to built-in keywords (100+ terms)
3. Never fails - always has keywords available

```
[*] No wordlist file found, using built-in keywords
[*] Random search mode enabled
[*] Using random keyword: technology
```

---

## Comparison Table

| Feature | Keyword Search | Random Search | Custom Wordlist |
|---------|---------------|---------------|-----------------|
| **Control** | Full control | Random | Controlled random |
| **Use Case** | Targeted search | Discovery | Domain-specific |
| **Efficiency** | High | High | High |
| **Repeatability** | Yes | No | No |
| **Setup** | None | None | Create wordlist |
| **Best For** | Known targets | Reconnaissance | Specialized searches |

---

## Combining with Other Options

### With Date Ranges
```bash
# Search for passwords in last month
./kasumi.pl --token xoxp-your-token \
    --keywords "password" \
    --from 2024-11-01 \
    --to 2024-11-30
```

### With Threads
```bash
# Include thread replies in search results
./kasumi.pl --token xoxp-your-token \
    --keywords "password" \
    --threads
```

### With Custom Output
```bash
# Save to custom file
./kasumi.pl --token xoxp-your-token \
    --random-search \
    --output findings_$(date +%Y%m%d).json
```

---

## Performance Tips

### For Keyword Search
1. **Be Specific**: More specific keywords = fewer results = faster
2. **Use Operators**: Slack operators help narrow results
3. **Date Ranges**: Limit scope with `--from` and `--to`
4. **Avoid Threads**: Skip `--threads` if not needed (faster)

### For Random Search
1. **Small Wordlists**: Smaller lists = more focused results
2. **Batch Processing**: Run multiple searches in parallel
3. **Filter Early**: Use date ranges to reduce scope
4. **Monitor Results**: Track which keywords find useful data

---

## Best Practices

### Security Assessments
```bash
# Create targeted wordlist for sensitive data
cat > sensitive.txt << 'EOF'
password
secret
api_key
token
credential
private_key
ssh_key
database
backup
EOF

# Run search
./kasumi.pl --token xoxp-your-token \
    --random-search \
    --wordlist sensitive.txt \
    --threads
```

### Compliance Monitoring
```bash
# Search for PII indicators
./kasumi.pl --token xoxp-your-token \
    --keywords "ssn social security credit-card"
```

### Incident Response
```bash
# Search for breach-related terms
./kasumi.pl --token xoxp-your-token \
    --keywords "hack breach compromised unauthorized" \
    --from 2024-12-01
```

---

## Next Steps

- [Download Modes](download-modes.md) - Learn about full download mode
- [Advanced Options](advanced-options.md) - Date ranges, threads, and more
- [Examples](examples.md) - Real-world usage scenarios
