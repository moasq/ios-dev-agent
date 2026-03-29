---
name: "revenuecat"
description: "Use when setting up or managing RevenueCat in-app purchases. Covers credential setup, product catalog creation, entitlements, offerings, and packages."
---

# RevenueCat Integration

Manage in-app purchases via RevenueCat REST API v2.

## Status Check

```bash
bash "$CLAUDE_PROJECT_DIR/.claude/scripts/revenuecat-api.sh" list-apps
```

If this fails with credential error, follow the [setup guide](reference/setup-guide.md).

## Workflow (in order)

1. **Products** — define what users can buy
2. **Entitlements** — define what access products grant
3. **Offerings** — group products into purchasable sets
4. **Packages** — organize products within offerings

## Quick Reference

```bash
# List products
bash .claude/scripts/revenuecat-api.sh list-products

# Create product
bash .claude/scripts/revenuecat-api.sh create-product '{
  "store_identifier": "com.mohammeds.migrainai.pro_monthly",
  "app_id": "APP_ID",
  "type": "subscription",
  "display_name": "Pro Monthly"
}'

# List entitlements
bash .claude/scripts/revenuecat-api.sh list-entitlements

# Create entitlement
bash .claude/scripts/revenuecat-api.sh create-entitlement '{
  "lookup_key": "pro",
  "display_name": "Pro Access"
}'

# Create offering
bash .claude/scripts/revenuecat-api.sh create-offering '{
  "lookup_key": "default",
  "display_name": "Default Offering"
}'
```

## Reference

- [setup-guide.md](reference/setup-guide.md) — get API key, configure credentials
- [catalog-management.md](reference/catalog-management.md) — complete product catalog example
