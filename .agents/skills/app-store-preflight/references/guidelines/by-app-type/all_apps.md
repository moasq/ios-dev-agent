# Checklist: All Apps (Universal Guidelines)

Guidelines that apply to **every** app regardless of category. Check these before every submission. Items marked with **[REAL REJECTION]** are patterns that have caused actual App Store rejections.

## Pre-Submission Essentials

- [ ] **2.1** — App is final, complete, tested for crashes and bugs
- [ ] **2.1** — All metadata is complete and accurate (no placeholder text, empty URLs)
- [ ] **2.1** — Demo account provided (or demo mode with prior Apple approval)
- [ ] **2.1** — Backend services are live and accessible during review
- [ ] **2.1(b)** — All configured IAP items are findable and functional (or explained in review notes)
- [ ] **2.3** — Review notes describe all non-obvious features

## Metadata

- [ ] **2.3.7** — App name ≤ 30 characters; unique; no trademark stuffing
- [ ] **2.3.7** — No pricing info, other app names, or irrelevant phrases in metadata
- [ ] **2.3.10** — No competitor platform names/icons (Android, Google Play, Samsung, Huawei, APK, etc.) in any metadata field. Replace with generic terms ("multiple platforms", "your previous device").
  - Detect: `grep -ri "android\|google play\|samsung\|huawei\|apk" ./metadata/`
- [ ] **2.3.3** — Screenshots show app in use (not just title art, login, or splash)
- [ ] **2.3.4** — App preview videos: screen captures only — no device frames, bezels, or non-app content. Static screenshots MAY use device frames. **[REAL REJECTION]**
- [ ] **2.3.8** — Metadata adheres to 4+ age rating (icons, screenshots, previews)
- [ ] **2.3.9** — Rights secured for all materials; fictional account data in screenshots
- [ ] **2.3.12** — What's New text describes significant changes

## Intellectual Property

- [ ] **5.2.5** — No Apple product images in app icon; no confusing Apple trademarks (iPhone, iPad, iCloud, Siri, etc.) in app name, subtitle, or metadata. **[REAL REJECTION]**
  - Detect: `grep -i "iphone\|ipad\|macbook\|apple watch\|imessage\|facetime\|siri\|icloud" ./metadata/`
- [ ] **5.2.5** — **WeatherKit attribution**: If the app uses WeatherKit, the Apple Weather trademark ( Weather) and legal link (https://weatherkit.apple.com/legal-attribution.html) MUST be displayed wherever weather data appears AND in Settings/About. **[REAL REJECTION]**
  - Detect: `grep -rn "import WeatherKit\|WeatherService" --include="*.swift" .` then verify `grep -rn "weatherkit.apple.com" --include="*.swift" .` returns matches

## Privacy & Data

- [ ] **5.1.1(i)** — Privacy policy linked in App Store Connect AND accessible in-app
- [ ] **5.1.1(ii)** — User consent secured for all data collection
- [ ] **5.1.1(iii)** — Only request data relevant to core functionality. Non-essential fields (phone, gender, marital status) must be optional with a Skip option. **[REAL REJECTION]**
- [ ] **5.1.1(iv)** — **Permission pre-prompt buttons**: Custom screens before system permission dialogs must use neutral button text ONLY ("Continue", "Next"). BANNED: "Allow Access", "Allow", "Enable", "Turn On", "Grant Permission". **[REAL REJECTION]**
- [ ] **5.1.1(iv)** — **Permission pre-prompt skip/dismiss**: Custom pre-permission screens must NOT include "Skip", "Not Now", "Maybe Later", or any dismiss button. The user must always proceed to the system dialog — the system's "Don't Allow" is the proper decline. **[REAL REJECTION]**
  - Detect: `grep -rn '"Allow Access"\|"Allow"\|"Enable"\|"Turn On"\|"Skip"\|"Not Now"' --include="*.swift" .` near permission request calls
- [ ] **5.1.1(v)** — If account creation exists, account deletion must be offered
- [ ] **5.1.2** — ATT framework required for cross-app tracking
- [ ] **Privacy Manifest** — `PrivacyInfo.xcprivacy` includes all Required Reason APIs (UserDefaults, file timestamps, system boot time, disk space). Required since Spring 2024. **[REAL REJECTION]**
  - Detect: `find . -name "PrivacyInfo.xcprivacy"` — must exist if app uses any Required Reason API

## Design & UX

- [ ] **4.1** — Not a copycat of another app
- [ ] **4.2** — Meaningful functionality beyond a repackaged website. Red flags: <3 screens, single WebView, no model layer, no offline capability, only static content. **[REAL REJECTION]**
- [ ] **4.8** — If social logins offered, must also offer Sign in with Apple (or equivalent)
- [ ] **4.0** — Sign in with Apple: don't re-ask name/email already provided by SIWA. Must handle `@privaterelay.appleid.com` relay emails. Must use standard `ASAuthorizationAppleIDButton`. **[REAL REJECTION]**
- [ ] **2.5.1** — Only public APIs; current OS; frameworks for intended purposes. Every entitlement in the project must be actively used in code — unused entitlements trigger information requests that block review. **[REAL REJECTION]**
  - Detect: Compare `plutil -p *.entitlements` against actual framework usage in code
- [ ] **2.5.5** — Fully functional on IPv6-only networks
- [ ] **2.5.14** — Explicit consent for recording user activity

## Business

- [ ] **3.1.1** — Digital content unlocks use IAP
- [ ] **3.2.1(x)** — Not forcing users to rate/review to access features
- [ ] **1.5** — Support URL with easy contact method
- [ ] **5.6.2** — Developer identity information is accurate and verifiable
