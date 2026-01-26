# Examples

Real-world usage examples for common scenarios.

## Table of Contents

- [Security & Penetration Testing](#security--penetration-testing)
- [Compliance & Legal](#compliance--legal)
- [Incident Response](#incident-response)
- [Data Analysis](#data-analysis)
- [Backup & Archival](#backup--archival)
- [Automation Scripts](#automation-scripts)

---

## Security & Penetration Testing

### Finding Exposed Credentials

```bash
# Search for password mentions
./kasumi.pl --token xoxp-your-token \
    --keywords "password senha contraseña" \
    --threads \
    --output findings/passwords.json

# Search for API keys
./kasumi.pl --token xoxp-your-token \
    --keywords "api-key api_key apikey api key" \
    --threads \
    --output findings/api_keys.json

# Search for tokens
./kasumi.pl --token xoxp-your-token \
    --keywords "token access_token bearer" \
    --threads \
    --output findings/tokens.json

# Search for secrets
./kasumi.pl --token xoxp-your-token \
    --keywords "secret private_key ssh-key" \
    --threads \
    --output findings/secrets.json
```

## Next Steps

- [Advanced Options](advanced-options.md) - Learn about all available options
- [Troubleshooting](troubleshooting.md) - Common issues and solutions
- [Search Modes](search-modes.md) - Keyword and random search
- [Download Modes](download-modes.md) - Understanding extraction modes
