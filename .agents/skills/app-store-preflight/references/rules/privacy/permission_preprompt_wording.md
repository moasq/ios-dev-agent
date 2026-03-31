# Rule: Permission Pre-Prompt Button Wording
- **Guideline**: 5.1.1(iv) – Legal – Privacy – Data Collection and Storage
- **Severity**: REJECTION
- **Category**: privacy

## What to Check
When the app shows a custom screen before the system permission dialog (a "pre-prompt"), the button that triggers the system dialog must use **neutral wording only**.

### Banned Button Labels
- "Allow Access"
- "Allow"
- "Enable"
- "Turn On"
- "Grant Permission"
- "Give Access"
- Any wording that mirrors the system dialog's "Allow" button

### Acceptable Button Labels
- "Continue"
- "Next"
- "Got It"
- "Sounds Good"

### Why Apple Rejects This
Apple considers pre-prompt buttons with permission-like wording ("Allow Access") as pressuring or manipulating the user into granting permission. The system dialog is the only place where "Allow" should appear. Custom screens must use neutral navigation language.

## How to Detect

### Code Inspection
```bash
# Find permission-related views (onboarding, settings, permission screens)
grep -rn "permission\|Permission\|onboarding\|Onboarding" --include="*.swift" .

# Search for banned button labels near permission request calls
grep -rn '"Allow Access"\|"Allow"\|"Enable"\|"Turn On"\|"Grant Permission"\|"Give Access"' --include="*.swift" .

# Find pre-prompt patterns: custom views that call requestAuthorization / requestWhenInUseAuthorization
grep -rn "requestAuthorization\|requestWhenInUseAuthorization\|requestAlwaysAuthorization\|requestAccess\|requestPermission" --include="*.swift" .
```

### UI Inspection
1. Run the app from a fresh install (reset simulator)
2. Walk through onboarding and any permission request flows
3. For each custom screen shown BEFORE a system permission dialog, check:
   - Does the button text use neutral wording ("Continue", "Next")?
   - Does the button text mimic the system dialog ("Allow", "Enable")?
4. Also check Settings screens that re-request permissions

## Resolution
1. Replace any banned button label with "Continue" or "Next"
2. The custom screen may explain WHY the permission is needed — that's encouraged
3. A "Skip" or "Not Now" option should also be available
4. Do NOT hide or minimize the skip option to pressure users

## Example Rejection
> **Guideline 5.1.1(iv) - Legal - Privacy - Data Collection and Storage**
>
> Issue Description
>
> The app encourages or directs users to allow the app to access the location. Specifically, the app directs the user to grant permission in the following way(s):
>
> - A custom message appears before the permission request, and to proceed users press a "Allow Access" button. Use words like "Continue" or "Next" on the button instead.
>
> Next Steps
>
> Revise the permission request process in the app to not display messages before the permission request with inappropriate words on buttons.
