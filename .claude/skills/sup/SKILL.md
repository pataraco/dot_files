---
name: sup
model: haiku
description: Provide a brief status update for the current session. Use this skill whenever the user types /sup, asks "what are we working on?", "what were we working on?", wants a quick session summary, or asks for a status check.
allowed-tools: [Read]
---

Provide a brief status update for the current session:

1. **Recent work**: Summarize what has been done this session (if nothing yet, say so briefly)
2. **Active tasks**: Check `.claude/TASKS.md` for any in-progress or pending tasks — list them if present

Keep it short — 5–8 lines max. No fluff.
