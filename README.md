# Kasumi - Slack Message Extractor

Tool to extract and search Slack messages from all accessible channels and direct messages using captured user tokens.

## Disclaimer

This tool is designed for authorized security assessments only. Unauthorized access to Slack workspaces or data extraction without proper authorization is illegal and unethical. Users are responsible for ensuring they have explicit permission and appropriate scope authorization before using this tool.

## Use Cases

During authorized engagements, this tool can be used to:

- **Credential Harvesting**: Search for passwords, API keys, tokens, and other credentials shared in messages
- **Infrastructure Mapping**: Discover internal systems, domains, IPs, and network architecture discussed in channels
- **Privilege Escalation**: Find administrator credentials or privileged account information
- **Lateral Movement**: Identify additional targets, user relationships, and access patterns
- **Data Exfiltration**: Extract sensitive business data, intellectual property, or confidential communications
- **Social Engineering**: Gather information about organizational structure, relationships, and communication patterns

## Features

- Extract messages from all accessible channels (public, private, DMs, group DMs)
- Extract thread replies for threaded conversations
- Filter by keywords (multiple keyword support, searches in threads too)
- Filter by date range
- Export results to JSON format
- Handles Slack API pagination automatically
- Rate limiting to respect API limits

## Prerequisites

### Perl Modules

Install the required Perl modules using cpanm:

```bash
cpanm --installdeps .
```

Or install manually:

```bash
cpanm LWP::UserAgent LWP::Protocol::https JSON HTTP::Request Readonly
```

### Slack User Token

This tool is designed for operations where you've obtained Slack user credentials during an engagement. It works with user tokens extracted from:

- Browser cookies (`d` cookie contains `xoxd-` token)
- Local Slack application data
- Memory dumps
- Configuration files
- Network traffic captures
- Phishing campaigns

#### Supported Token Types

| Token Type | Description | Cookie Required |
|------------|-------------|-----------------|
| `xoxp-` | OAuth user token (legacy) | No |
| `xoxc-` | Session token (cookie-based) | Yes (`--cookie-d`) |

**Important:** The `xoxc-` tokens are extracted from browser sessions and require the `d` cookie value to authenticate. Without the `d` cookie, authentication will fail.

#### How to Extract Tokens and Cookies

**For `xoxc-` tokens (most common):**

1. Open Slack in your browser
2. Open DevTools (F12)
3. Go to **Application** → **Cookies** → `https://app.slack.com`
4. Find and copy:
   - Token: Look for `xoxc-` in localStorage or network requests
   - Cookie: The `d` cookie value (starts with `xoxd-`)

**For `xoxp-` tokens:**

OAuth tokens (`xoxp-`) are standalone and don't require cookies. These can be found in:
- OAuth app configurations
- Environment variables
- Configuration files

#### Token Extraction Locations

Common locations where Slack tokens can be found:

**Browser Storage:**
- Chrome/Edge: `%APPDATA%\Local\Google\Chrome\User Data\Default\Cookies` (Windows)
- Chrome/Edge: `~/Library/Application Support/Google/Chrome/Default/Cookies` (macOS)
- Firefox: `cookies.sqlite` in profile directory

**Slack Desktop App:**
- Windows: `%APPDATA%\Slack\storage\` or `%APPDATA%\Slack\Local Storage\`
- macOS: `~/Library/Application Support/Slack/storage/` or `~/Library/Application Support/Slack/Local Storage/`
- Linux: `~/.config/Slack/storage/` or `~/.config/Slack/Local Storage/`

**Memory/Process Dumps:**
- Look for strings matching `xoxp-`, `xoxc-`, or `xoxd-` patterns

#### Token Format

Tokens typically follow these patterns:
```
xoxp-XXXXXXXXXX-XXXXXXXXXX-XXXXXXXXXXXX-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
xoxc-XXXXXXXXXXXX-XXXXXXXXXXXX-XXXXXXXXXXXX-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
xoxd-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

## Usage

### Basic Usage with OAuth Token (xoxp-)

Extract all messages using an OAuth token (no cookie required):

```bash
./kasumi.pl --token xoxp-your-oauth-token
```

### Basic Usage with Session Token (xoxc-)

Extract messages using a session token (requires `d` cookie):

```bash
./kasumi.pl --token xoxc-your-session-token --cookie-d "xoxd-your-d-cookie-value"
```

### Filter by Keywords

Search for messages containing specific keywords:

```bash
./kasumi.pl --token xoxp-token --keywords "password credentials api"
```

The keywords are space-separated, and messages matching ANY keyword will be included.

**Common keyword search patterns for red team operations:**

```bash
# Credential harvesting
./kasumi.pl --token xoxp-token --keywords "password pass pwd credential secret token key api aws"

# Infrastructure discovery
./kasumi.pl --token xoxp-token --keywords "server prod production staging vpn ip address subnet"

# Database and systems
./kasumi.pl --token xoxp-token --keywords "database db mysql postgres admin root ssh rdp"

# Code repositories and deployment
./kasumi.pl --token xoxp-token --keywords "github gitlab repository deploy jenkins pipeline"
```

### Filter by Date Range

Extract messages from a specific date range:

```bash
# From a specific date to now
./kasumi.pl --token xoxp-token --from 2024-01-01

# Specific date range
./kasumi.pl --token xoxp-token --from 2024-01-01 --to 2024-12-31
```

### Extract Thread Replies

Enable thread extraction to get all replies in conversation threads:

```bash
./kasumi.pl --token xoxp-token --threads
```

When `--threads` is enabled:
- Thread replies are fetched for all messages that have threads
- Keyword search will also search within thread replies
- Output includes a `thread_replies` array for each threaded message

### Combined Filters

Combine keywords, date range, and thread extraction:

```bash
./kasumi.pl --token xoxc-session-token \
  --cookie-d "xoxd-cookie-value" \
  --keywords "password vpn credentials database" \
  --from 2024-01-01 \
  --to 2024-12-31 \
  --threads \
  --output sensitive_data.json
```

### Command-Line Options

```
Required:
  --token <TOKEN>        Slack token (xoxp-... for OAuth, xoxc-... for session)

Authentication:
  --cookie-d <VALUE>     Required when using xoxc- tokens (d cookie value)

Search Options:
  --keywords <TEXT>      Search for specific keywords (space-separated)
  --random-search        Use random keywords from wordlist
  --wordlist <FILE>      Custom wordlist for random search (default: wordlist.txt)
  --context <NUM>        Capture N messages before/after each match

Download Options:
  --download-all         Download ALL messages from all conversations
  --size-limit <MB>      Size limit in MB for --download-all (default: 1024)

Filter Options:
  --from <DATE>          Extract messages from this date (YYYY-MM-DD)
  --to <DATE>            Extract messages until this date (YYYY-MM-DD)
  --threads              Extract thread replies for threaded messages

Output Options:
  --output <FILE>        Output JSON file (default: slack_messages.json)

Other:
  --no-verify-ssl        Disable SSL certificate verification (testing only!)
  --help                 Show help message
```

## Output Format

The script generates a JSON file with the following structure:

```json
{
  "extraction_date": "Thu Dec  5 08:30:00 2024",
  "total_messages": 42,
  "total_thread_replies": 15,
  "filters": {
    "keywords": "important urgent",
    "date_from": "2024-01-01",
    "date_to": "2024-12-31",
    "threads": true
  },
  "messages": [
    {
      "type": "message",
      "user": "U12345678",
      "text": "This is an important message",
      "ts": "1704110400.123456",
      "reply_count": 3,
      "conversation_name": "general",
      "conversation_type": "Public Channel",
      "conversation_id": "C12345678",
      "thread_replies": [
        {
          "type": "message",
          "user": "U87654321",
          "text": "Thanks for the update!",
          "ts": "1704110500.123457",
          "thread_ts": "1704110400.123456"
        },
        {
          "type": "message",
          "user": "U11111111",
          "text": "Agreed, this is urgent",
          "ts": "1704110600.123458",
          "thread_ts": "1704110400.123456"
        }
      ]
    }
  ]
}
```

### Message Fields

- `type` - Message type (usually "message")
- `user` - User ID who sent the message
- `text` - Message content
- `ts` - Timestamp in Slack format
- `reply_count` - Number of replies in the thread (if threaded)
- `conversation_name` - Name of the channel/DM
- `conversation_type` - Type of conversation (Public Channel, Private Channel, Direct Message, Group Direct Message)
- `conversation_id` - Slack conversation ID
- `thread_replies` - Array of reply messages (only present when `--threads` is used and message has replies)
- Additional fields may be present depending on message type (attachments, files, reactions, etc.)

**Thread Reply Fields:**
- `thread_ts` - Timestamp of the parent message in the thread
- All other standard message fields (type, user, text, ts)

## Operational Security Notes

**For Red Team Operators:**

- **Never commit captured tokens to version control or reports**
- Store extracted tokens securely in your engagement documentation
- Tokens provide full access to the compromised user's Slack workspace
- Be aware that Slack activity may be logged and monitored by blue teams
- Consider the scope and authorization of your engagement before extraction
- Tokens may expire or be revoked if the user logs out or changes passwords
- Some organizations use SSO/SAML which may have additional session controls

**Detection Considerations:**

- Unusual API access patterns may trigger security alerts
- Access from unexpected IP addresses/geolocations can be flagged
- High-volume data extraction may be noticed by SOC teams
- Consider rate limiting and off-hours operation for stealth

### Using Environment Variables

For operational security, avoid passing tokens directly on command line:

```bash
export SLACK_TOKEN="xoxc-captured-token-here"
export SLACK_COOKIE="xoxd-cookie-value-here"
./kasumi.pl --token $SLACK_TOKEN --cookie-d $SLACK_COOKIE --keywords "search term"
```

This prevents token exposure in process listings and shell history.

## Rate Limiting

The script includes automatic rate limiting (1 second delay between API calls) to respect Slack's API limits. For workspaces with many channels, extraction may take some time.

## Troubleshooting

### "Cookie-based authentication requires --cookie-d parameter"

When using `xoxc-` tokens, you must provide the `d` cookie:

```bash
./kasumi.pl --token xoxc-... --cookie-d "xoxd-..."
```

If you don't have the `d` cookie, you need to extract it from the browser alongside the token.

### "Failed to fetch conversations" Error

- Verify the captured token is in the correct format (`xoxp-` or `xoxc-`)
- For `xoxc-` tokens, ensure you have the correct `d` cookie value
- Token may have expired or been revoked (user logged out, password changed)
- User may have been deactivated or removed from workspace
- IP-based restrictions or anomaly detection may be blocking access

### SSL/TLS Errors

If you encounter SSL verification errors, ensure your system has up-to-date CA certificates:

```bash
# macOS
brew install openssl

# Debian/Ubuntu
sudo apt-get install ca-certificates

# Install Perl SSL modules
cpanm LWP::Protocol::https Mozilla::CA
```

### Missing Messages

- Slack API may not return messages from archived channels by default
- Private channels require explicit membership
- Some message types (like ephemeral messages) are not stored

## License

This is free and unencumbered software released into the public domain.

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.
