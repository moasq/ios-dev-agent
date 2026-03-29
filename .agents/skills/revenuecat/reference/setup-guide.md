# RevenueCat Setup Guide

## Step 1: Create Account

Go to [app.revenuecat.com](https://app.revenuecat.com) and create an account.

## Step 2: Create Project

Create a new project (or use existing).

## Step 3: Get Project ID

From the project URL: `https://app.revenuecat.com/projects/<PROJECT_ID>/...`

## Step 4: Generate Secret API Key

1. Go to project settings → API Keys
2. Create a new **Secret API key (v2)** with write access
3. Copy the key (starts with `sk_`)

## Step 5: Store Credentials

Edit `.claude/settings.local.json` and fill in:

```json
{
  "env": {
    "REVENUECAT_SECRET_KEY": "sk_your_key_here",
    "REVENUECAT_PROJECT_ID": "your-project-id-here"
  }
}
```

## Step 6: Verify

```bash
bash .claude/scripts/revenuecat-api.sh list-apps
```

Should return your app list.

## Step 7: Add purchases-ios SPM Package

Use xcodegen MCP:
```
mcp__xcodegen__add_package with:
  name: "purchases-ios"
  url: "https://github.com/RevenueCat/purchases-ios"
  from: "5.0.0"
  product: "RevenueCat"
```

## Troubleshooting

| Error | Cause | Fix |
|---|---|---|
| 401 Unauthorized | Bad API key | Verify `sk_` key is correct |
| 404 Not Found | Bad project ID | Check project ID from URL |
| Empty apps list | No app created | Create an iOS app in RevenueCat dashboard |
