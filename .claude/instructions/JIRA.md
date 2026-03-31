# Claude Jira Workflow Instructions

Instructions for Claude AI on how to handle Jira ticket management using `jirapi`.

## Overview

The `jirapi` command provides a clean interface to company Jira instance. Use it to help maintain tickets based on conversation context, reducing the need for manual browser-based updates.

## Default Project Key

If the user provides only a ticket number (e.g., `1317`), assume the project key is the value of `JIRA_PROJECT` from `~/.jira/config` and expand it to the full key (e.g., `JIRA_PROJECT-1317`). Only use a different project key if the user explicitly provides one.

## When to Update Jira

### Automatically Update (No Confirmation Needed)

**Add comments when:**
- User explicitly states work is complete on a ticket
- User mentions finishing/completing a specific task with ticket number
- User provides a clear status update for a ticket

**Examples:**
```
User: "I'm done with PROJECT-1143, completed the migration"
→ jirapi comment PROJECT-1143 "Completed migration"

User: "Finished deploying PROJECT-1192 to staging"
→ jirapi comment PROJECT-1192 "Deployed to staging"
```

### Ask for Confirmation First

**Before:**
- Creating new tickets (always confirm details)
- Updating descriptions (user may want to review)
- Bulk operations affecting multiple tickets
- Changing ticket status/transitions
- Any operation that's unclear or ambiguous

## Comment Guidelines

### Format & Content

**Keep comments:**
- **Concise** - 1-2 sentences typically
- **Specific** - What was actually done
- **Professional** - Clear, factual language
- **Context-aware** - Include relevant details from conversation

**Good comments:**
```
"Completed migration to CloudOS SLSv4. Deployed to staging and verified."
"Updated Jenkinsfile to remove explicit Snowflake context per new requirements."
"Fixed Terraform planning script - now handles net-new resources correctly."
```

**Avoid:**
- Overly verbose explanations
- Unnecessary pleasantries
- Redundant information already in the ticket
- Technical jargon without context

### Comment Structure

When user provides detailed information:
```
[Main accomplishment]

Details:
- [Detail 1]
- [Detail 2]
- [Detail 3]
```

When user provides simple completion:
```
[Single line describing what was done]
```

### PR Link Format Standard

**ALWAYS include links to related PRs in comments.**

**Required format:**
```
git-org/git-repo #PR-NUMBER: [PR Title](PR-URL)
```

**Examples:**
```
git-org/my-repo #15: [feat: add new feature with comprehensive updates](https://git.company.com/git-org/my-repo/pull/15)

my-org/my-service #42: [feat: add user authentication](https://github.com/my-org/my-service/pull/42)
```

**In comments:**
```
Fixed Terraform planning script to handle net-new deployments. Script now gracefully handles missing state files and provides comprehensive execution summaries.

PRs:
- git-org/my-repo #15: [feat: add new feature with comprehensive updates](https://git.company.com/git-org/my-repo/pull/15)
- git-org/my-repo #16: [docs: docs: improve documentation](https://git.company.com/git-org/my-repo/pull/16)

Tested with both net-new and existing deployments.
```

**Note:** User's repos may be on GitHub Enterprise (git.company.com) or public GitHub (github.com). Use the appropriate domain.

## Maintaining Checklists

### When to Update Checklists

Update checklists in ticket descriptions when:
- User explicitly mentions completing checklist items
- User asks you to update the checklist
- Clear evidence that a checklist item is complete

### Checklist Format

Always use these emoji characters for checklists:
- ⬜️ for unchecked/incomplete items
- ✅ for checked/complete items
- 🚧 for in-progress/under construction
- ❌ for will not do / not applicable

Example:
```
⬜️ Deploy to staging
✅ Update documentation
🚧 Run integration tests
❌ Update legacy config (N/A)
```

### Process

1. Read current description: `jirapi view TICKET-KEY`
2. Identify checklist items
3. Update the relevant item(s)
4. Write updated description: `jirapi update-desc TICKET-KEY "updated text"`

**Always show the user what you're updating before doing it.**

## Creating New Tickets

### When User Requests

When user asks to create a ticket, gather information interactively:

1. **Type**: Story, Bug, Task, Spike, or Epic?
2. **Summary**: Clear, concise title (50-70 chars)
3. **Description**: Detailed information including:
   - Context/background
   - Objectives
   - Technical details
   - Implementation checklist
4. **Acceptance Criteria**: Asked separately (separate field in Jira)

### Use Templates

Templates are available at `~/.jira/templates/`:
- `story.txt` - User stories
- `bug.txt` - Bug reports
- `task.txt` - General tasks
- `spike.txt` - Research/investigation
- `epic.txt` - Epics

**Note:** Acceptance criteria should NOT be in the description (separate field).

### Ticket Metadata

**IMPORTANT:** When creating new tickets, always include these fields using values from `~/.jira/config`:

1. **Component**: Ask user which component to use (default: see `JIRA_DEFAULT_COMPONENT_NAME` in config)
   - Available components are listed in config file
   - Use component ID from config: `JIRA_DEFAULT_COMPONENT_ID`

2. **Labels**: Use current fiscal quarter label from config
   - Variable: `JIRA_CURRENT_LABEL` (source from config — changes quarterly)
   - This changes quarterly - always source from config

3. **Epic Link**: Link to current quarter's support epic
   - Variable: `JIRA_CURRENT_EPIC_KEY` (source from config — changes quarterly)
   - Epic name available in: `JIRA_CURRENT_EPIC_NAME`
   - Changes quarterly - always source from config

4. **Teams**: Always set to the default DevOps team
   - Variable: `JIRA_DEFAULT_TEAM_ID` (source from config)
   - Variable: `JIRA_DEFAULT_TEAM_NAME` (source from config)
   - Field ID: `JIRA_FIELD_TEAMS` (source from config)

**Known field IDs and formats (confirmed working):**
- Epic Link: `${JIRA_FIELD_EPIC_LINK}` — string value (e.g. epic key)
- Teams: `${JIRA_FIELD_TEAMS}` — **must be a string ID**, not an object
- Assignee: use `name` key with `${JIRA_USERNAME}` (NOT email — `${JIRA_USER}`)

**Using the REST API to set these fields:**
```bash
source ~/.jira/config
TOKEN=$(security find-generic-password -a "${JIRA_KEYCHAIN_ACCOUNT}" -s "${JIRA_KEYCHAIN_SERVICE}" -w)
curl -s -X POST -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  "${JIRA_ENDPOINT}/rest/api/2/issue" \
  -d "{
    \"fields\": {
      \"project\": {\"key\": \"${JIRA_PROJECT}\"},
      \"summary\": \"Ticket summary\",
      \"issuetype\": {\"name\": \"Task\"},
      \"description\": \"Description here\",
      \"assignee\": {\"name\": \"${JIRA_USERNAME}\"},
      \"priority\": {\"name\": \"3. Major\"},
      \"components\": [{\"id\": \"${JIRA_DEFAULT_COMPONENT_ID}\"}],
      \"labels\": [\"${JIRA_CURRENT_LABEL}\"],
      \"${JIRA_FIELD_EPIC_LINK}\": \"${JIRA_CURRENT_EPIC_KEY}\",
      \"${JIRA_FIELD_TEAMS}\": \"${JIRA_DEFAULT_TEAM_ID}\"
    }
  }"
```

### Creation Process

1. Gather information through conversation
2. **Ask user for component** (default to `JIRA_DEFAULT_COMPONENT_NAME` from config if not specified)
3. Show user the ticket preview:
   ```
   Type: Story
   Summary: Add user authentication to dashboard
   Component: <COMPONENT_NAME>
   Labels: <CURRENT_LABEL>
   Epic Link: <CURRENT_EPIC_NAME> (<CURRENT_EPIC_KEY>)
   Teams: <TEAM_NAME>

   Description:
   [show full description]

   Acceptance Criteria:
   [show criteria]
   ```
4. Ask for confirmation
5. Create using: `jirapi new` (or programmatically with REST API including metadata)
6. Report back ticket key and URL

## Researching PRs and Updating Tickets

### When User Mentions Completing Work

If user says they completed work on a ticket but doesn't provide details:

**Proactive approach:**
1. Ask: "Which repo/PRs relate to this work?"
2. Research the PRs using `gh` CLI
3. Summarize what was done from PR descriptions
4. Add comprehensive comment to Jira with PR links
5. Optionally close/transition the ticket if appropriate

### PR Research Workflow

```bash
# List recent merged PRs
gh pr list --repo git.company.com/org/repo --state merged --limit 5

# Get PR details
gh pr view PR-NUMBER --repo git.company.com/org/repo --json title,body,url

# Alternative: User provides repo URL
# Extract org/repo from: https://git.company.com/git-org/my-repo
```

### Example Workflow

```
User: "I want to complete the terraform planning script ticket"

Claude:
1. Ask: "Which repo has the related PRs?"
2. User provides: "https://git.company.com/git-org/my-repo"
3. Research recent merged PRs in that repo
4. Identify relevant PRs (last 2-5 merged)
5. Read PR descriptions and summarize work done
6. Create comprehensive Jira comment with:
   - Summary of what was accomplished
   - Links to PRs in standard format
   - Testing/verification notes from PRs
7. Ask: "Should I close this ticket?"
8. If yes, transition to appropriate status
```

### Comment with PR Research

**Format:**
```
[Summary of work accomplished based on PR descriptions]

PRs:
- git-org/repo #NUM: [PR Title](URL)
- git-org/repo #NUM: [PR Title](URL)

[Any testing/verification notes from PRs]
```

**Example:**
```
Fixed Terraform planning script to handle net-new deployments. Script now gracefully handles missing state files (expected for new infrastructure) and provides comprehensive execution summaries showing plan results for all modules. Also improved documentation with clear usage examples and prerequisites.

PRs:
- git-org/my-repo #15: [feat: add new feature with comprehensive updates](https://git.company.com/git-org/my-repo/pull/15)
- git-org/my-repo #16: [docs: improve script header and usage documentation](https://git.company.com/git-org/my-repo/pull/16)

Tested with both net-new and existing deployments.
```

## Ticket Discovery

### When User References Work

If user mentions work but doesn't specify a ticket:

1. **Check their assigned tickets:**
   ```bash
   jirapi list --mine --limit 20
   ```

2. **Identify likely ticket** based on:
   - Keywords in summary
   - Recent activity
   - Status (In Progress likely candidates)

3. **Confirm with user:**
   ```
   "I found PROJECT-1143: [SDLC Migration] Update Secrets Rotation Repos
   Is this the ticket you're referring to?"
   ```

4. **Then update** once confirmed

### Searching for Tickets

Use JQL queries when needed:
```bash
# Recently updated tickets
jirapi list --query "assignee=currentUser() AND updated >= -7d"

# Specific status
jirapi list --query "project=PROJECT AND status='In Progress'"
```

## Error Handling

### PAT Expiration

If you see:
```
❌ ERROR: Your Jira PAT has expired
```

**Tell the user:**
```
Your Jira PAT has expired. Please update it:
1. Create a new PAT in Jira (check ~/.jira/config for the endpoint)
2. Run: jirapi token-update
3. Paste the new token
```

### API Errors

If API calls fail:
- Check the error message
- Verify ticket key exists
- Confirm user has permissions
- Suggest manual verification if needed

## Closing/Transitioning Tickets

### When to Close Tickets

**Close tickets when:**
- User explicitly says to close it
- Work is complete and user says "close it" or "mark it done"
- After adding completion comment, user confirms closure

**DON'T automatically close without asking** - always confirm first.

### How to Close Tickets

1. **Get auth token and endpoint from config:**
   ```bash
   source ~/.jira/config
   TOKEN=$(security find-generic-password -a "${JIRA_KEYCHAIN_ACCOUNT}" -s "${JIRA_KEYCHAIN_SERVICE}" -w)
   ```

2. **Always look up available transitions** (they can change):
   ```bash
   curl -s -H "Authorization: Bearer ${TOKEN}" \
     "${JIRA_ENDPOINT}/rest/api/2/issue/TICKET-KEY/transitions" | \
     jq -r '.transitions[] | "\(.id) | \(.name) | \(.to.name)"'
   ```

3. **Execute transition:**
   ```bash
   curl -s -X POST -H "Authorization: Bearer ${TOKEN}" \
     -H "Content-Type: application/json" \
     -d '{"transition":{"id":"TRANSITION-ID"}}' \
     "${JIRA_ENDPOINT}/rest/api/2/issue/TICKET-KEY/transitions"
   ```

### Workflow

```
1. Add completion comment with PR links
2. Ask user: "Should I close this ticket?"
3. If yes:
   - Get available transitions
   - Execute appropriate transition (usually "Close Issue")
   - Confirm: "✓ Ticket closed"
4. Verify status with `jirapi view TICKET-KEY`
```

### Example

```
User: "I want to complete TICKET-123"

Claude:
1. Research PRs
2. Add comment with summary + PR links
3. Ask: "Should I close this ticket?"
4. User: "yes close it"
5. Get transitions for TICKET-123
6. Execute "Close Issue" transition (ID: 771)
7. Confirm: "✓ TICKET-123 is now closed"
```

## Updating the jirapi Script

### When to Update the Script

**Add new features when:**
- User requests functionality that will be used **more than once**
- The operation is **complex** (avoid repeating complexity)
- It's a **common operation** that should have been in the script
- It adds **long-term value** to the tool

**Use raw API calls when:**
- One-off operation rarely needed
- Quick exploratory/testing operation
- Very specialized edge case

### Update Process

1. **Identify the need**: User requests something or you recognize a gap
2. **Assess frequency**: Will this be used again?
3. **Propose to user**:
   ```
   "This would be useful to add to jirapi. Should I:
   - Add a new command/feature to the script?
   - Just do it once with a raw API call?"
   ```
4. **If updating script**:
   - Read the current script: `~/.local/bin/jirapi`
   - Add the new command/subcommand function
   - Update the help text
   - Test the new functionality
   - Update `~/.jira/README.md` if significant feature

### Example: Adding New Feature

```
User: "Can you assign tickets to people?"

Claude assessment:
- Will be used repeatedly ✓
- Common operation ✓
- Should be in script ✓

Response:
"The script doesn't have an 'assign' command yet. I can add it -
it would let you (and me) assign tickets easily. Should I add it?"

If yes:
1. Add cmd_assign() function to jirapi
2. Add to main dispatcher
3. Add help text
4. Test it
5. Update README
```

### What NOT to Add

Don't add to the script:
- One-time data migrations
- Highly specific queries for current work only
- Experimental/testing operations
- Anything that duplicates existing functionality

### Script Locations

- Main script: `~/.local/bin/jirapi`
- Library functions: `~/.jira/lib.sh`
- Documentation: `~/.jira/README.md`

## Workflow Examples

### Example 1: Work Completion

```
User: "Just finished the serverless migration for PROJECT-812"

Claude:
1. Recognize: Work completion + ticket reference
2. Add comment: jirapi comment PROJECT-812 "Completed serverless migration"
3. Respond: "✓ Added comment to PROJECT-812"
```

### Example 2: Multiple Updates

```
User: "Deployed PROJECT-1192 to staging, updated docs, and ran tests"

Claude:
1. Recognize: Detailed completion
2. Add comment with details:
   jirapi comment PROJECT-1192 "Deployed to staging. Updated documentation and verified with test suite."
3. Respond: "✓ Updated PROJECT-1192 with deployment details"
```

### Example 3: Checklist Update

```
User: "Can you mark 'Deploy to staging' as done in PROJECT-1143?"

Claude:
1. Read current description: jirapi view PROJECT-1143
2. Show user current checklist
3. Ask confirmation: "I'll update the checklist to mark 'Deploy to staging' as complete. Proceed?"
4. Update description with checked item
5. Confirm: "✓ Checklist updated in PROJECT-1143"
```

### Example 4: New Ticket Creation

```
User: "Create a story for adding SSO authentication"

Claude:
1. Ask questions:
   - "What type of SSO? (SAML, OAuth, etc.)"
   - "Which applications need this?"
   - "Any specific requirements or constraints?"
2. Draft ticket with template
3. Show preview
4. Get confirmation
5. Create ticket
6. Report: "✓ Created PROJECT-XXXX: Add SSO authentication"
```

## Best Practices

### DO

✅ Be proactive - if user mentions completing work, update Jira
✅ Keep comments concise and professional
✅ Use context from conversation in comments
✅ Confirm before bulk operations or creating tickets
✅ Show user what you're doing ("Adding comment to PROJECT-123...")
✅ Report results with ticket URLs for reference

### DON'T

❌ Add comments without clear indication work was done
❌ Make assumptions about which ticket user means
❌ Create tickets without gathering full requirements
❌ Update descriptions without showing user first
❌ Use overly verbose or casual language in tickets
❌ Forget to report back what you did

## Command Quick Reference

```bash
# List tickets
jirapi list --mine                    # Your assigned tickets
jirapi list --sprint                  # Current sprint
jirapi list --query "JQL"             # Custom query

# View ticket
jirapi view PROJECT-1143           # Full ticket details

# Add comment
jirapi comment PROJECT-1143 "text" # Add comment

# Update description
jirapi update-desc PROJECT-1143    # Opens editor
jirapi update-desc PROJECT-1143 "new text"  # Direct update

# Get help
jirapi help                          # Main help
jirapi <command> --help              # Command-specific help
```

## Notes

- All connection details (endpoint, project, board ID) are in `~/.jira/config`
- Auth token: sourced via keychain using `JIRA_KEYCHAIN_ACCOUNT` and `JIRA_KEYCHAIN_SERVICE` from config
- Templates: `~/.jira/templates/`
- Config: `~/.jira/config`
- README: `~/.jira/README.md`

## Version

Instructions version: 1.4.1
Last updated: 06-03-2026 (v1.4.1)
