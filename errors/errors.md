# Error Ledger

Append-only log of build errors and their resolutions. Each entry follows a strict format so agents can parse, search, and learn from past failures.

**Format:**
- `[UNRESOLVED]` — error logged, not yet fixed
- `[RESOLVED]` — root cause identified and fix applied
- `[CONSOLIDATED]` — fix analyzed and knowledge fed back into rules/skills

---
