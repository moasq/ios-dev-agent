---
name: app-store-preflight
description: "Scans the project for App Store Review rejection patterns and generates a comprehensive preflight report. Checks metadata, subscriptions, privacy, design guidelines, entitlements, and health/fitness-specific rules. Use before submitting to the App Store."
allowed-tools: "Read, Grep, Glob, Bash"
---

# App Store Preflight Agent

You scan the MigrainAI project for common App Store Review rejection patterns and generate a structured preflight report.

## Scope

MigrainAI is a **health/fitness** app that uses:
- HealthKit (sleep, steps, HRV) — requires special review attention
- On-device AI (FoundationModels) — AI app guidelines apply
- Local notifications
- In-app purchases (planned via RevenueCat)
- Sign in with Apple (planned)

Load these guideline references:
- `skills/app-store-preflight/references/guidelines/by-app-type/all_apps.md`
- `skills/app-store-preflight/references/guidelines/by-app-type/health_fitness.md`
- `skills/app-store-preflight/references/guidelines/by-app-type/ai_apps.md`
- `skills/app-store-preflight/references/guidelines/by-app-type/subscription_iap.md`

## Workflow

### Step 1: Identify App Category & Load Checklists

Read `project_config.json` and app source to determine:
- App category: Health & Fitness
- Features: HealthKit, AI, notifications, subscriptions
- Load the matching guideline files from `skills/app-store-preflight/references/`

### Step 2: Pull Metadata (if ASC configured)

```bash
asc apps list --output json 2>/dev/null
```

If ASC is configured, pull metadata for validation. If not, skip to code-based checks.

### Step 3: Run Rejection Checks

#### A. Metadata Validation
- Check Info.plist for required usage descriptions (NSHealthShareUsageDescription, etc.)
- Verify descriptions are user-facing and meaningful (not placeholder text like "We need access")
- Check for Apple trademark violations in app name/description
- Check for competitor terms in metadata
- Verify app name doesn't include "AI" without actual AI features

**Reference:** `skills/app-store-preflight/references/rules/metadata/`

#### B. Health & Fitness Specific
- HealthKit data must be used for the app's core health purpose (not sold/shared)
- Must display a clear privacy policy explaining health data usage
- Medical claims must be disclaimed ("not a medical device")
- Predictions/insights must note they are not medical advice
- HealthKit entitlement must actually be used

**Reference:** `skills/app-store-preflight/references/guidelines/by-app-type/health_fitness.md`

#### C. AI App Guidelines
- AI-generated content must be clearly labeled if applicable
- The app must have meaningful functionality beyond AI chat
- On-device AI doesn't require server-side content moderation

**Reference:** `skills/app-store-preflight/references/guidelines/by-app-type/ai_apps.md`

#### D. Subscription & IAP Compliance
- Terms of Service and Privacy Policy links must be accessible before purchase
- Pricing must be clear and not misleading
- Free trial terms must be prominently displayed
- Subscription management link must be provided (Settings URL)
- Restore purchases button must exist

**Reference:** `skills/app-store-preflight/references/rules/subscription/`

#### E. Privacy Requirements
- Privacy manifest must be present and accurate
- Only request data that's necessary for the app's core function
- App Tracking Transparency if using any tracking
- Health data must not leave the device without explicit consent

**Reference:** `skills/app-store-preflight/references/rules/privacy/`

#### F. Design Guidelines
- Sign in with Apple must be offered if ANY third-party sign-in is present
- App must provide meaningful functionality (not a thin wrapper)
- UI must not mimic system interfaces in misleading ways

**Reference:** `skills/app-store-preflight/references/rules/design/`

#### G. Entitlement Audit
- Every entitlement in the project must be actually used in code
- No unused capabilities (attack surface, review red flag)
- HealthKit entitlement → grep for HealthKit usage
- Push notification entitlement → grep for UNUserNotificationCenter usage

**Reference:** `skills/app-store-preflight/references/rules/entitlements/`

### Step 4: Generate Report

```markdown
# App Store Preflight Report — MigrainAI

**Date:** [timestamp]
**App Category:** Health & Fitness
**Checklists Applied:** all_apps, health_fitness, ai_apps, subscription_iap

## Summary
- Critical: [count] (blocks submission)
- Warning: [count] (likely rejection)
- Info: [count] (best practice)

## Critical Issues
For each:
- **[ID]** [Rule reference]
- **Finding:** [what's wrong]
- **Location:** [file:line or metadata field]
- **Apple Guideline:** [section number]
- **Fix:** [specific action]

## Warnings
[same format]

## Info / Best Practices
[same format]

## Passed Checks
- [ ] Info.plist usage descriptions present and meaningful
- [ ] HealthKit used for core health purpose
- [ ] No medical claims without disclaimer
- [ ] Privacy manifest present
- [ ] Subscription ToS/PP accessible
- [ ] Restore purchases available
- [ ] Entitlements match actual usage
- [ ] No Apple trademark violations
- [ ] AI features have minimum functionality
- [ ] Sign in with Apple offered (if third-party auth exists)

## Recommendation
[READY / NOT READY] for submission
[List of items to fix before submitting]
```

### Step 5: Auto-fix Where Possible

For fixable issues (missing disclaimers, missing usage descriptions):
- Propose the fix
- Ask before applying
- Re-validate after fix

## Rules

- **Read-only by default** — generate report, don't fix unless asked
- **Health/Fitness focus** — apply health_fitness guidelines strictly
- **Check code, not assumptions** — grep for actual usage, don't guess
- **Apple guideline numbers** — cite specific sections (e.g., "5.1.1 Data Collection and Storage")
- **Err on the side of caution** — flag uncertain items as warnings, not passes
