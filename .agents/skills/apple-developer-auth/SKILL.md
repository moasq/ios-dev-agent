---
name: apple-developer-auth
description: "Authenticate to Apple Developer Portal. Interactive menu with two modes: Sign In (Apple ID + password + 2FA via SRP-6a) or Manual (.p8 API key). Shows green/red/yellow status. Revoke option. Zero external dependencies."
---

# Apple Developer Authentication

Tell the user to run the interactive menu:
```
! python3 .claude/scripts/apple-developer-auth.py
```

## What the menu shows

**If not connected** (red):
```
  ● Not connected

  [1] Sign in  (Apple ID + password + 2FA)
  [2] Manual   (provide .p8 API key for asc CLI)
```

**If connected** (green):
```
  ● Connected  as user@apple.com
    Session age: 3d — valid for ~27d more

  [1] Revoke session (sign out)
  [2] List apps
  [3] List certificates
  [4] List profiles
  [5] Register bundle ID
  [6] Setup asc CLI (.p8 key)
```

**If expired** (yellow):
```
  ● Expired  session for user@apple.com

  [1] Sign in
  [2] Manual
  [3] Revoke (clear expired session)
```

## Direct commands

For non-interactive use (e.g. from Claude):
```bash
# Sign in
! python3 .claude/scripts/apple-developer-auth.py login --user user@apple.com

# Check status (validates live against Apple)
! python3 .claude/scripts/apple-developer-auth.py status

# Revoke / sign out
! python3 .claude/scripts/apple-developer-auth.py revoke

# Portal operations
! python3 .claude/scripts/apple-developer-auth.py list-apps
! python3 .claude/scripts/apple-developer-auth.py list-certs
! python3 .claude/scripts/apple-developer-auth.py list-profiles
! python3 .claude/scripts/apple-developer-auth.py register-bundle com.example.app "My App"

# Manual .p8 key setup
! python3 .claude/scripts/apple-developer-auth.py setup-asc
```

## Auth flow internals (mirrors Fastlane Spaceship)

1. Widget key from `appstoreconnect.apple.com/olympus/v1/app/config`
2. Hashcash proof-of-work (SHA-1, `X-Apple-HC-Bits`/`X-Apple-HC-Challenge`)
3. SRP-6a: `signin/init` (sends A, receives B+salt+iterations) → PBKDF2 → `signin/complete` (sends M1+M2)
4. 2FA: device push or SMS (user types code, or `sms` to switch)
5. Trust: `GET /appleauth/auth/2sv/trust`
6. Cookies persisted at `~/.apple-developer-auth/cookies.txt` (~30 days)

## Status validation

`status` and `menu` validate **live** — not just checking if a cookie file exists. They call Apple's Olympus session endpoint and report:
- **Green (valid)**: Cookie exists AND Apple accepted it
- **Yellow (expired)**: Cookie exists but Apple rejected it
- **Red (not connected)**: No session at all

## Environment variables

| Variable | Purpose |
|---|---|
| `APPLE_ID` | Apple ID email (skips prompt) |
| `APPLE_PASSWORD` | Password (skips prompt) |
| `APPLE_2FA_SMS` | Phone number for auto-SMS 2FA |
