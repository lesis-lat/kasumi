# Kasumi Documentation

Welcome to the Kasumi documentation! Kasumi is a powerful Slack message extraction tool designed for security researchers, IT administrators, and anyone who needs to extract and analyze Slack messages.

## Table of Contents

1. [Authentication](authentication.md) - How to authenticate with Slack
2. [Search Modes](search-modes.md) - Different ways to search messages
3. [Download Modes](download-modes.md) - Search vs. Full Download
4. [Advanced Options](advanced-options.md) - Date ranges, threads, and more
5. [Examples](examples.md) - Practical use cases and examples
6. [Troubleshooting](troubleshooting.md) - Common issues and solutions

## Quick Start

### Basic Keyword Search
```bash
./kasumi.pl --token xoxp-your-token --keywords "password"
```

### Download All Messages
```bash
./kasumi.pl --token xoxp-your-token --download-all
```

### Random Search
```bash
./kasumi.pl --token xoxp-your-token --random-search
```

## Features Overview

### Search Capabilities
- **Keyword Search**: Use Slack's native search API for efficient, targeted searches
- **Random Search**: Automatically search using random keywords
- **Custom Wordlists**: Provide your own wordlist for random searches

### Download Capabilities
- **Full Download**: Download all messages from all conversations
- **Size Limits**: Set custom size limits (default 1GB)
- **Offline Use**: Perfect for offline analysis with tools like grep, jq, etc.

### Advanced Features
- **Thread Extraction**: Include thread replies in your results
- **Date Filtering**: Filter messages by date range
- **Multiple Auth Methods**: Support for OAuth and cookie-based authentication
- **SSL Options**: Disable SSL verification for testing environments

## Architecture

Kasumi operates in two distinct modes:

1. **Search Mode** (--keywords)
   - Uses Slack's `search.messages` API
   - Filters server-side before download
   - Efficient for specific queries

2. **Download Mode** (--download-all)
   - Uses `conversations.list` and `conversations.history` APIs
   - Downloads everything for offline use
   - Respects size limits

## Output Format

Results are saved as JSON with the following structure:

```json
{
  "extraction_date": "Fri Dec 5 14:27:32 2025",
  "total_messages": 1234,
  "total_thread_replies": 56,
  "filters": {
    "keywords": "password",
    "date_from": "2024-01-01",
    "date_to": "2024-12-31",
    "threads": true
  },
  "messages": [...]
}
```

## Security Considerations

- Never commit your Slack tokens to version control
- Use environment variables for tokens when possible
- Be careful with `--no-verify-ssl` - only use in testing
- Review extracted data before sharing
- Follow your organization's data handling policies

## Contributing

If you find bugs or have feature requests, please open an issue on the project repository.

## License

Check the main README.md in the project root for license information.
