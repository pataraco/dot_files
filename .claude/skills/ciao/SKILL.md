---
name: ciao
model: haiku
description: End of session wrap-up — summarize work done and optionally add a journal entry. Use this skill whenever the user types /ciao, says "wrap up", "end of session", "i'm done for today", "let's call it", says "i'm signing off", or otherwise signals they're finishing the session.
allowed-tools: [Read, Bash]
---

End of session wrap-up:

1. Summarize the work done during the session (brief bullet points)
2. Ask if they'd like to add an entry to their daily journal (`~/notes/Daily_Journal.txt`)
3. If yes: write the entry in `DD-MM-YYYY: <description>` format, inserted in chronological order

Then remind the user to type `/exit` or press `Ctrl+C` to close the session.
