# Checklist: AI-Powered / Generative AI Apps

Guidelines specifically applying to apps that use AI services (ChatGPT, Gemini, Claude, etc.), generative AI, or deep synthesis technology. Items marked with **[REAL REJECTION]** are patterns that have caused actual App Store rejections.

## Critical (Will Reject)

- [ ] **5 (China DST)** — If distributing in China: remove all references to OpenAI, ChatGPT, GPT, Gemini, Claude, Anthropic, Midjourney, DALL-E, Copilot, Stable Diffusion from metadata across ALL locales (not just zh-Hans). Apple reviews all locales when the app is available in China. **[REAL REJECTION]**
  - Detect: `grep -ri "chatgpt\|openai\|gpt-4\|gemini\|claude\|anthropic\|midjourney\|dall-e\|copilot" ./metadata/`
  - Options: (1) Remove references, use "AI-powered" generically (2) Deselect China mainland in ASC (3) Obtain MIIT license
- [ ] **5 (China DST)** — If distributing in China: suppress AI functionality or obtain MIIT license
- [ ] **1.1.6** — No false information or misleading AI capabilities (e.g., "AI doctor")
- [ ] **1.4.1** — AI health advice: must include medical disclaimers; can't substitute for professional diagnosis
- [ ] **2.3.1** — All AI features documented in review notes; no hidden AI capabilities

## Important (Common Rejections)

- [ ] **2.1** — Review notes MUST proactively state whether AI is on-device or cloud-based. Apple will ask "Does your app use third-party AI?" — answer it upfront. **[REAL REJECTION]**
- [ ] **2.1** — If on-device AI (FoundationModels, Core ML, MLX): state explicitly that no user data is sent to any server
- [ ] **2.1** — If third-party AI (OpenAI, Google, etc.): list which personal data is sent, and confirm explicit user consent exists in the UI
- [ ] **2.1** — If local model download (MLX, Core ML from remote): clarify that only model weights are downloaded, no user data is transmitted
- [ ] **5.2.5** — Don't use "GPT", "ChatGPT", "OpenAI", "Gemini" as part of app name unless you are the brand owner
- [ ] **2.3.7** — Don't keyword-stuff with AI brand names (ChatGPT, GPT-4, Gemini, etc.)
- [ ] **1.2** — If AI generates user-facing content: implement content moderation/filtering
- [ ] **5.1.1** — Disclose AI data processing in privacy policy
- [ ] **2.5.14** — Explicit consent required for AI processing of user recordings/inputs
- [ ] **5.1.1(iii)** — Data minimization: don't send more data to AI than necessary
- [ ] **3.1.1** — AI features/credits unlocked via IAP (not external payment for digital content)
