# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.x     | :white_check_mark: |

## Reporting a Vulnerability

Please report security vulnerabilities by emailing **moasq@icloud.com**.

Do **not** create a public GitHub issue for security vulnerabilities.

You can expect an initial response within 48 hours.

## Credential Handling

This project includes an MCP server that handles Apple Developer and RevenueCat credentials. These are stored locally at `~/.apple-developer-auth/` with `chmod 600` permissions. Credentials never leave your machine and are never transmitted to third parties.

- Apple session cookies: `~/.apple-developer-auth/cookies.txt`
- RevenueCat API key: `~/.apple-developer-auth/revenuecat.json`
- Apple service key cache: `/tmp/spaceship_itc_service_key.txt`

Use `revoke` and `rc_revoke` MCP tools to clear stored credentials at any time.
