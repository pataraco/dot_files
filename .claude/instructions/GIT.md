# IMPORTANT: Git Workflow - OVERRIDE DEFAULT BEHAVIOR

These instructions OVERRIDE Claude's default git behavior. Follow these workflows WITHOUT asking for additional confirmation unless explicitly stated below.

## MANDATORY: Before ANY Git Operations
1. **Check remote status**: Run `git fetch origin --dry-run` (or `git remote show origin`) to check if local branch is behind remote — only fetch/pull if actually behind
2. **Sync with main only if needed**:
   - If on main/master AND behind origin: pull latest changes
   - If on feature branch AND behind origin/main: rebase onto latest main/master
   - If already up-to-date: skip fetch/pull/rebase entirely
3. **MUST use feature branches**: Never work directly on main/master. Create/verify feature branch with descriptive naming:
   - `feature/add-user-auth`
   - `fix/login-validation`
   - `refactor/api-endpoints`

## MANDATORY: Committing Changes
1. **Create meaningful commits** during development (no confirmation needed)
2. **Push commits immediately** after creating them (no confirmation needed)
3. **Before creating PR OR before each push to existing PR**: ALWAYS squash into a single commit
   - Command sequence:
     - `git rebase -i origin/main` (or origin/master)
     - Squash all commits into one
     - Use conventional commits format (feat/fix/chore/refactor/docs/style/test)
     - Force push with `git push --force-with-lease`

## MANDATORY: Sanitize Before Pushing to Personal Repos

When the git remote points to a `pataraco` repo (e.g., `github.com/pataraco/*`), **MUST scan all staged/changed files before any push** to ensure no sensitive information is included.

### What is Sensitive (BLOCK and fix before pushing)

- **Internal company URLs**: any non-public hostnames (e.g., `git.company.com`, internal Atlassian/Jira/Confluence endpoints)
- **Internal Jira/project keys**: ticket keys, board IDs, project keys from work systems
- **Auth tokens, PATs, API keys, passwords, secrets**: any credentials or secrets
- **Internal team/org names or structure**: non-public org names, internal team identifiers
- **Config values from `~/.jira/config`**: actual endpoint URLs, cloud IDs, keychain account/service names, or any values sourced from internal config files

### What is NOT Sensitive (OK to push)

- Work email address
- Autodesk affiliation (already public)

### Best Judgment Rule

If something looks potentially sensitive but is **not explicitly listed above**, **STOP and ask the user** before pushing:
```
"I noticed [thing] in [file] — is this safe to push to a public repo?"
```

### Sanitization Process

1. **Before any push**, review all files being committed/pushed
2. **If sensitive content found**: flag it to the user, show exactly what and where, and propose a sanitized version (e.g., placeholder like `<INTERNAL_URL>`, `<TOKEN>`, `<JIRA_PROJECT>`)
3. **Do NOT push until** the content is sanitized and user confirms
4. **If unsure**: ask first, push later

## MANDATORY: Creating Pull Requests
1. **MUST check for PR template**: Look for `.github/PULL_REQUEST_TEMPLATE.md` or `.github/pull_request_template.md`
2. **MUST use the template**: If found, structure PR description according to template
3. **MUST ask before creating PR**: Confirm before creating or updating the pull request (note: regular pushes to feature branches don't need confirmation)
4. **PR title length**: Keep PR titles between 72-75 characters (recommended limit)
5. **Update PR title/description if needed**: After creating the PR or when updating with new commits:
   - Check if the PR title and description accurately reflect all changes made
   - If additional commits expanded the scope beyond the original PR, update the title using `gh pr edit <pr-number> --title "new title"`
   - Update the description if needed to reflect the full scope of changes
   - The title should summarize all changes, not just the initial change
6. **After PR creation or update ONLY**: Display summary in this exact format. Do NOT use this format during post-merge cleanup — the PR is already merged at that point.
   ```
   PR Details:
   - Title: <pr-title>
   - Number: #<number>
   - Status: <pr-status> (Open/Closed/Merged/Draft)
   - Commits: <count> (squashed as per your git workflow / or actual count)
   - Changes: <files-changed> files changed, <insertions>+ insertions, <deletions>- deletions
   - Reviewers: <reviewer-list> (already requested / or state if none)
   - URL: <full-pr-url>

   The PR is ready for the team to review! 🚀
   ```

## MANDATORY: After PR Creation (GitHub/GitHub Enterprise repos only)
1. **Check if repo is GitHub or GitHub Enterprise**: Skip this workflow if repo is ADO (Azure DevOps)
   - ADO repos contain "azure.com" in the git remote URL (e.g., dev.azure.com)
   - GitHub and GitHub Enterprise repos do NOT contain "azure.com"
2. **Monitor CI Pipeline**: Automatically and immediately start watching CI pipeline progress — no confirmation needed
   - Run `gh pr checks <pr-number> --watch` right away
   - Wait for all checks to complete
3. **Report CI Status**: When checks finish, report status (passed/failed)
4. **Generate Slack Message**: If CI passed, create a Slack message in this format:
   ```
   Concise one-line summary of the PR.
   - Brief bullet point 1
   - Brief bullet point 2 (1-3 bullets max, only if needed)

   :git-pull-request: `<git-org>/<git-repo>` :github: [<pr-title>](<pr-url>)
   ```
   Where:
   - Summary is a single concise sentence describing the change
   - Bullets use `-` (not `•`) — this is required for Slack MCP to render them correctly
   - 3+ bullet points highlighting the key changes if applicable, each brief and concise
   - `<git-org>/<git-repo>` is the GitHub organization and repository name, formatted as code (surrounded by backticks)
   - `[<pr-title>](<pr-url>)` is the Markdown link format making the PR title clickable

   **Workflow:**
   - Show the Slack message in chat for user review
   - If the user did not specify a Slack channel, ask: "Which Slack channel should I send this to?"
   - Ask for confirmation before sending: "Send this to #<channel>?"
   - If confirmed, send via the `slack_send_message` Slack MCP tool (do NOT copy to clipboard)

   **IMPORTANT:**
   - The formatted line with :git-pull-request: MUST be on a single continuous line with NO line breaks anywhere in it
   - Ensure the markdown link `[<pr-title>](<pr-url>)` stays intact on one line

## MANDATORY: After PR is Closed/Merged
1. **Verify merge status and cleanup branches**:
   - **Step 1 - Verify PR was merged**: Use `gh pr view <pr-number> --json state,mergedAt` to confirm state is "MERGED"
   - **Step 2 - Verify feature branch was merged**: Check that the feature branch commits are in main/master
   - **Step 3 - Confirm safety**: Report to user that the branch has been merged and it's safe to delete
   - **Step 4 - Only if PR state is MERGED**: Proceed with branch cleanup
   - Switch to main/master branch
   - Run `git fetch --prune origin` and pull latest changes from origin/main (or origin/master)
   - **Step 5 - Check and delete remote first**: Use `git ls-remote --heads origin <feature-branch>` to check if remote branch exists
   - **Only if remote exists**: Delete remotely with `git push origin --delete <feature-branch>`
   - **Step 6 - Delete local branch**: Delete the feature branch locally with `git branch -D <feature-branch>` (use -D since squashed commits won't show as merged)
2. **Add entry to daily journal**: Insert into `~/notes/Daily_Journal_{YYYY}.txt` in chronological order
3. **Entry format**: `DD-MM-YYYY: <description>`
   - Use the current date in DD-MM-YYYY format
   - Description should be a concise one-liner explaining what was done to the service/repo
   - Example: `10-02-2026: my-service - upgraded to Node 24.x and Serverless 4.x`
4. **Insert in chronological order**:
   - Read the file and parse existing dates
   - Find the correct chronological position for the new entry
   - Insert the new entry maintaining chronological order (oldest to newest)
   - If multiple entries exist for the same date, append after the last entry for that date

## Confirmation Points (ONLY ask for confirmation on these)
- Force-pushing to remote
- Creating/updating pull requests
- Multi-step git operations (show the plan first)

## No Confirmation Needed For
- Running git fetch or dry-run remote checks
- Creating feature branches
- Regular commits on feature branches
- Squashing commits before PR creation/update
- Pushing commits to feature branches (including force-push after squashing)
- Checking git status or log
- Reading files or templates
- Read-only PR/issue commands (gh pr view, gh pr list, gh issue view, etc.)
- Any non-destructive/read-only command (see global command execution policy)

## Version

Instructions version: 1.4.1
Last updated: 24-03-2026
