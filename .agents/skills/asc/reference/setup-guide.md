# ASC CLI Setup Guide

## Step 1: Install

```bash
brew install asc
```

## Step 2: Generate API Key

1. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. Navigate to **Users and Access** → **Integrations** → **App Store Connect API**
3. Click **Generate API Key**
4. Select **Admin** role
5. Download the `.p8` private key file
6. Note the **Key ID** and **Issuer ID** shown on the page

## Step 3: Store the Key

```bash
mkdir -p ~/.asc
mv ~/Downloads/AuthKey_KEYID.p8 ~/.asc/
chmod 600 ~/.asc/AuthKey_KEYID.p8
```

## Step 4: Configure Credentials

Edit `.claude/settings.local.json`:

```json
{
  "env": {
    "ASC_KEY_ID": "YOUR_KEY_ID",
    "ASC_ISSUER_ID": "YOUR_ISSUER_ID",
    "ASC_KEY_PATH": "~/.asc/AuthKey_YOUR_KEY_ID.p8"
  }
}
```

## Step 5: Authenticate

```bash
asc auth login \
  --name "MigrainAI" \
  --key-id "$ASC_KEY_ID" \
  --issuer-id "$ASC_ISSUER_ID" \
  --private-key "$ASC_KEY_PATH"
```

## Step 6: Verify

```bash
asc apps list
```

## Important Notes

- The `.p8` key can only be downloaded ONCE from Apple. Keep it safe.
- Keys expire after 1 year. Rotate before expiration.
- Admin role gives full access. Use App Manager for limited scope.
- The `asc` CLI stores credentials in macOS Keychain after first login.
