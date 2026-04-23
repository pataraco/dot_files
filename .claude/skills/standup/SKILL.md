---
name: standup
model: sonnet
description: Summarize work from recent working days for standup. Use this skill whenever the user types /standup, says "standup", "what did I work on?", "generate my standup", "daily standup", or needs a summary of recent work for a team update. Supports /standup, /standup devops, /standup migrations, /standup sdlc.
allowed-tools: [Bash, mcp__slack__slack_send_message, mcp__slack__slack_search_channels, mcp__slack__slack_search_public_and_private]
---

Generate a standup summary from my daily journal and Slack messages.

## Argument Parsing

The user may invoke this skill as:
- `/standup` → devops mode (default)
- `/standup devops` → devops mode
- `/standup migrations` → migrations mode
- `/standup sdlc` → migrations mode

The user may also append inline context anywhere in the prompt, in any of these forms:
- `working on:` / `today:` / `t:` → today's work items
- `blockers:` / `b:` → blocker items

Parse these out before generating the summary. Split on ` and ` and `,` to produce individual bullet points. Strip trailing punctuation.

## Mode Differences

| | Devops | Migrations |
|---|---|---|
| **Date range** | All working days since last standup (Mon/Wed) | Yesterday + today only |
| **Title** | `DevOps Standup - <date>` | `SaaS SDLC Migrations Standup - <date>` |
| **Default Slack channel** | `#priv-saas-devops` (ID: `C033HD3483E`) | `#wlc-nimbus-standup` (ID: `C0AL3VBQXCZ`) |

## Steps (apply to both modes)

1. Get today's date and day of week: `date +"%A %d-%m-%Y"`
2. Determine the date range for the detected mode (see Date Range Rules below)
3. Run these **in parallel** for every date in the range:
   - Fetch journal entries: `grep "^DD-MM-YYYY:" ~/notes/Daily_Journal_{YYYY}.txt`
   - Search Slack for sent messages: `mcp__slack__slack_search_public_and_private` with query `from:<@U020UA11RFT> on:YYYY-MM-DD`
     - Exclude chatter (short replies, reactions, DMs with no work content)
     - Focus on substantive messages: work updates, PRs, decisions, coordination
4. Cross-reference Slack messages against journal entries:
   - Identify work items in Slack **not already captured** in the journal
   - Append missing items to `~/notes/Daily_Journal_{YYYY}.txt` as `DD-MM-YYYY: <repo/topic> - <description>`, in chronological order
   - Briefly note: "Added X journal entries from Slack."
5. Extract inline `today:` / `working on:` / `t:` and `blockers:` / `b:` context from the prompt
6. Generate the summary using both sources

## Date Range Rules

### Devops Mode
Include all working days since the last standup (Mon and Wed only), up to and including today:
- **Monday**: last Wed + Thu + Fri + Mon
- **Wednesday**: Mon + Tue + Wed
- **Other days**: sum from last standup day (e.g. Thu → Wed+Thu, Fri → Wed+Thu+Fri)

### Migrations Mode
- **Monday**: Fri + Mon
- **Any other weekday**: yesterday + today

Skip weekends when counting back.

## Output Format (both modes)

Format as Slack-compatible markdown:
- `**bold**` for section headers (NOT `*bold*`)
- `-` for bullets (NOT `•`)
- `  -` (2-space indent) for sub-bullets
- Blank line between each section header and its bullets

Structure:

**<Title> - <today's date in DD-MMM-YYYY format, e.g. 09-APR-2026>**

:yesterday: **Yesterday<( date range for devops)>:**

- <topic/repo>
  - <action item 1>
  - <action item 2>

:today: **Today:**

- <today/working-on items from prompt, one bullet each>
- <other planned work inferred from journal, if any>

:blocker: **Blocker(s):**

- <blockers from prompt, one bullet each; otherwise "None">

### Grouping rules (Yesterday section only)

**Goal: TL;DR. Nobody reads long standups. Aim for a summary that can be skimmed in ~20 seconds.**

- Every topic/repo gets a parent bullet (`- <topic>`) with **1–3 sub-bullets max (hard cap)**
- **Consolidate, don't enumerate**: collapse multi-step work into outcome-focused bullets. Do NOT split journal entries on semicolons — treat semicolons as within-bullet separators, not bullet boundaries
- **Lead with what shipped**: merged / deployed / decided first; in-progress second; drop pure planning ("next step", "next session — X")
- **One outcome per sub-bullet**: group related actions that describe a single outcome into one bullet (e.g., "PR #9 merged — secrets migration, EB discovery, stage compat")
- **Drop noise**:
  - investigation trail details → keep only the finding ("confirmed X was dead code" — not the 5-parallel-investigation play-by-play)
  - coordination chatter (pings, review requests, @-mentions without substance)
  - admin/meta work (todo organization, memory saves)
  - repeated context across days (don't restate the same work item twice)
- **Cap total length**: target under 20 lines for devops (multi-day), under 12 for migrations (2-day)
- Today and Blockers sections stay flat (no sub-bullets)

### Example

Given two journal entries for `saas-workspace`:
```
25-03-2026: saas-workspace - switched to common-test-secrets; updated e2e env vars; removed warmup plugin; PR #7 ready
25-03-2026: saas-workspace - resolved warmup blocker; confirmed provisionedConcurrency approach; notified team
```

**Good (TL;DR):**
```
- saas-workspace
  - PR #7 ready — common-test-secrets migration, e2e env vars, warmup removed
  - resolved warmup blocker with provisionedConcurrency approach
```

**Bad (too verbose, one bullet per semicolon):**
```
- saas-workspace
  - switched to common-test-secrets
  - updated e2e env vars
  - removed warmup plugin
  - PR #7 ready
  - resolved warmup blocker
  - confirmed provisionedConcurrency approach
  - notified team
```

## Post-Display Actions (both modes)

After displaying the summary, ask:

> What would you like to do?
> a) Copy to clipboard
> b) Send to Slack (default: #priv-saas-devops or #wlc-nimbus-standup depending on mode)
> c) Modify

- **a)** Run `pbcopy` with the summary text → confirm "Copied to clipboard."
- **b)** Send via `slack_send_message` MCP tool to the mode's default channel, unless the user specifies another. Use the `message` parameter (NOT `text`). Return the message link.
- **c)** Ask what changes they'd like, update, display again, re-prompt with a/b/c.

The user may respond with just a letter, number, or short phrase. Handle all naturally.

## Notes

- Today's date is $CURRENT_DATE
- **TL;DR is the goal**: terse, outcome-led, skimmable. If it reads like an essay, cut it in half
- Sub-bullets should be phrases, not sentences — no trailing context or qualifiers
- If no journal entries found for the date range, say so
- For migrations mode, focus on SDLC/migration-related work; include other work only if no migration work is found
- Each `today`/`working on`/`blockers` item from the prompt should be its own bullet
