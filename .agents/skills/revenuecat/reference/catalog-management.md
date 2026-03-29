# RevenueCat Catalog Management

## Complete Example: Pro Monthly Subscription

### 1. Create Product

```bash
bash .claude/scripts/revenuecat-api.sh create-product '{
  "store_identifier": "com.mohammeds.migrainai.pro_monthly",
  "app_id": "APP_ID_FROM_LIST_APPS",
  "type": "subscription",
  "display_name": "Pro Monthly"
}'
```

Note the returned `id` (e.g., `prod_xxxxx`).

### 2. Create Entitlement

```bash
bash .claude/scripts/revenuecat-api.sh create-entitlement '{
  "lookup_key": "pro",
  "display_name": "Pro Access"
}'
```

Note the returned `id` (e.g., `entl_xxxxx`).

### 3. Attach Product to Entitlement

```bash
bash .claude/scripts/revenuecat-api.sh attach-products "entl_xxxxx" '{
  "product_ids": ["prod_xxxxx"]
}'
```

### 4. Create Offering

```bash
bash .claude/scripts/revenuecat-api.sh create-offering '{
  "lookup_key": "default",
  "display_name": "Default Offering"
}'
```

Note the returned `id` (e.g., `ofrngl_xxxxx`).

### 5. Create Package

```bash
bash .claude/scripts/revenuecat-api.sh create-package "ofrngl_xxxxx" '{
  "lookup_key": "monthly",
  "display_name": "Monthly",
  "position": 1
}'
```

### 6. Get Public API Key (for app-side SDK)

```bash
bash .claude/scripts/revenuecat-api.sh get-api-keys "APP_ID"
```

Use the returned public key in your app's `Purchases.configure(withAPIKey:)`.

## App-Side Integration

```swift
import RevenueCat

// In App init or AppDelegate
Purchases.configure(withAPIKey: "appl_public_key_here")

// Check subscription status
let customerInfo = try await Purchases.shared.customerInfo()
let isPro = customerInfo.entitlements["pro"]?.isActive == true

// Present paywall
let offerings = try await Purchases.shared.offerings()
if let current = offerings.current {
    // Show packages to user
}

// Purchase
let result = try await Purchases.shared.purchase(package: package)
```
