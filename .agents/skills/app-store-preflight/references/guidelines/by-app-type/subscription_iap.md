# Checklist: Apps with Subscriptions / In-App Purchases

Guidelines that specifically apply to apps offering auto-renewable subscriptions, consumable/non-consumable IAP, or freemium models. Items marked with **[REAL REJECTION]** are patterns that have caused actual App Store rejections.

## Critical (Will Reject)

- [ ] **3.1.1** — All digital content unlocks use Apple's In-App Purchase (no license keys, QR codes, crypto)
- [ ] **3.1.2(a)** — Subscription provides ongoing value; minimum 7-day period; works on all user devices
- [ ] **3.1.2(c)** — Subscription purchase screen clearly describes what user gets for the price
- [ ] **3.1.2** — **Billed amount is the most prominent pricing element**. Calculated monthly pricing ("only $2.50/mo") must be subordinate in font size, weight, color contrast, and position to the actual billed amount ("$29.99/year"). Free trial text must not overshadow post-trial price. **[REAL REJECTION]**
  - Detect: `grep -rn "perMonth\|per_month\|monthly.*price" --include="*.swift" .` — if found, verify visual hierarchy
- [ ] **3.1.2** — App description includes functional **Terms of Use (EULA)** link in every locale. Use Apple standard EULA link or custom EULA in App Store Connect. **[REAL REJECTION]**
  - Detect: `grep -i "terms" ./metadata/version/<VERSION>/*.json` — must match
- [ ] **3.1.2** — App description includes functional **Privacy Policy** link
- [ ] **5.1.1(i)** — Privacy Policy URL set in App Store Connect metadata (required when selling subscriptions or IAPs)
- [ ] **3.1.1** — Loot boxes / randomized items disclose odds before purchase
- [ ] **3.1.1** — In-game currencies purchased via IAP do not expire
- [ ] **3.1.1** — Restore Purchases mechanism exists for restorable IAP
- [ ] **2.1(b)** — All IAP items are complete, visible to reviewer, and functional

## Important (Common Rejections)

- [ ] **3.1.2(b)** — Seamless upgrade/downgrade; no accidental duplicate subscriptions
- [ ] **2.3.2** — Description/screenshots clearly indicate which features require additional purchase
- [ ] **3.1.2(a)** — Not taking away functionality previously paid for when switching to subscription model
- [ ] **3.1.2(a)** — Free trial clearly identifies duration, what ends, and post-trial charges
- [ ] **4.10** — Not charging for built-in OS capabilities (Push, camera, iCloud)
- [ ] **3.2.1(x)** — Not forcing users to rate/review app to access features

## In-App Subscription Screen Must Include

- [ ] Title of subscription
- [ ] Length of subscription period
- [ ] Price (and price per unit if appropriate)
- [ ] Functional tappable Privacy Policy link
- [ ] Functional tappable Terms of Use / EULA link
