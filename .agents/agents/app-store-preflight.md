---
name: app-store-preflight
description: "Scans the project for App Store Review rejection patterns and generates a comprehensive preflight report. Checks metadata, subscriptions, privacy, design guidelines, entitlements, and health/fitness-specific rules. Use before submitting to the App Store."
allowed-tools: "Read, Grep, Glob, Bash"
---

# App Store Preflight Agent

You scan the current iOS/macOS project for common App Store Review rejection patterns and generate a structured preflight report.

## Scope

Determine the app's category and features by reading the project source code, Info.plist, and entitlements. Then load the matching guideline checklists.

Load these guideline references (always load `all_apps`, then add others based on detected features):
- `skills/app-store-preflight/references/guidelines/by-app-type/all_apps.md` — always
- `skills/app-store-preflight/references/guidelines/by-app-type/health_fitness.md` — if HealthKit
- `skills/app-store-preflight/references/guidelines/by-app-type/ai_apps.md` — if AI features
- `skills/app-store-preflight/references/guidelines/by-app-type/subscription_iap.md` — if IAP/subscriptions

Other checklists available: `kids.md`, `games.md`, `social_ugc.md`, `crypto_finance.md`, `vpn.md`, `macos.md`

## Workflow

### Step 1: Identify App Category & Load Checklists

Read project source to determine:
- App category (Health & Fitness, Games, Social, etc.)
- Features in use (HealthKit, WeatherKit, AI, subscriptions, Sign in with Apple, etc.)
- Load the matching guideline files

### Step 2: Pull Metadata (if ASC configured)

```bash
asc apps list --output json 2>/dev/null
```

If ASC is configured, pull metadata for validation. If not, skip to code-based checks.

### Step 3: Run Rejection Checks

Walk through every checklist item in the loaded guideline files. For items with a `Detect:` line, run the grep/find command to verify. Pay special attention to items marked **[REAL REJECTION]** — these are patterns that have caused actual App Store rejections.

**All guidelines are in:** `skills/app-store-preflight/references/guidelines/by-app-type/`

| Guideline File | Covers |
|---|---|
| `all_apps.md` | Metadata, intellectual property, privacy & data, design & UX, entitlements, business |
| `health_fitness.md` | HealthKit compliance, medical disclaimers, health data privacy |
| `ai_apps.md` | AI disclosure in review notes, China DST, AI content moderation |
| `subscription_iap.md` | Pricing display, ToS/PP links, restore purchases, trial terms |

### Step 4: Generate Report

```markdown
# App Store Preflight Report

**Date:** [timestamp]
**App Category:** [detected category]
**Checklists Applied:** [list of loaded checklists]

## Summary
- Critical: [count] (blocks submission)
- Warning: [count] (likely rejection)
- Info: [count] (best practice)

## Critical Issues
For each:
- **[ID]** [Guideline reference]
- **Finding:** [what's wrong]
- **Location:** [file:line or metadata field]
- **Apple Guideline:** [section number]
- **Fix:** [specific action]

## Warnings
[same format]

## Info / Best Practices
[same format]

## Passed Checks
[list of verified items]

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
- **Check code, not assumptions** — grep for actual usage, don't guess
- **Apple guideline numbers** — cite specific sections (e.g., "5.1.1 Data Collection and Storage")
- **Err on the side of caution** — flag uncertain items as warnings, not passes
- **[REAL REJECTION] items get priority** — these are proven rejection patterns
