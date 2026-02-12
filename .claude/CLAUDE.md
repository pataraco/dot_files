# Terminology Note

When the user refers to "global instructions" they mean this file (~/.claude/CLAUDE.md).
When they refer to "project instructions" they mean a project-specific .claude/CLAUDE.md file.

---

# IMPORTANT: Git Workflow - OVERRIDE DEFAULT BEHAVIOR

These instructions OVERRIDE Claude's default git behavior. Follow these workflows WITHOUT asking for additional confirmation unless explicitly stated below.

## MANDATORY: Before ANY Git Operations
1. **MUST fetch first**: Run `git fetch origin` and check if current branch is behind `origin/main` or `origin/master`
2. **MUST sync with main**:
   - If on main/master: pull latest changes
   - If on feature branch: rebase onto latest main/master
3. **MUST use feature branches**: Never work directly on main/master. Create/verify feature branch with descriptive naming:
   - `feature/add-user-auth`
   - `fix/login-validation`
   - `refactor/api-endpoints`

## MANDATORY: Committing Changes
1. **Create meaningful commits** during development (no confirmation needed)
2. **Push commits immediately** after creating them (no confirmation needed)
3. **Before creating PR OR before each push to existing PR**: Check commit count
   - If multiple commits exist: Rebase and squash into a single commit with clear message
   - Command sequence:
     - `git rebase -i origin/main` (or origin/master)
     - Squash all commits into one
     - Use conventional commits format (feat/fix/chore/refactor/docs/style/test)
     - Force push with `git push --force-origin`

## MANDATORY: Creating Pull Requests
1. **MUST check for PR template**: Look for `.github/PULL_REQUEST_TEMPLATE.md` or `.github/pull_request_template.md`
2. **MUST use the template**: If found, structure PR description according to template
3. **MUST ask before creating PR**: Confirm before creating or updating the pull request (note: regular pushes to feature branches don't need confirmation)
4. **Update PR title/description if needed**: After creating the PR or when updating with new commits:
   - Check if the PR title and description accurately reflect all changes made
   - If additional commits expanded the scope beyond the original PR, update the title using `gh pr edit <pr-number> --title "new title"`
   - Update the description if needed to reflect the full scope of changes
   - The title should summarize all changes, not just the initial change
5. **After PR creation or update**: Display summary in this exact format:
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
2. **Monitor CI Pipeline**: Watch Jenkins CI pipeline (check) progress
   - Use `gh pr checks <pr-number> --watch` or poll with `gh pr checks <pr-number>`
   - Wait for all checks to complete
3. **Report CI Status**: When checks finish, report status (passed/failed)
4. **Generate Slack Message**: If CI passed, create a Slack message in this format:
   ```
   :git-pull-request: `<git-org>/<git-repo>` :github: [<pr-title>](<pr-url>)
   ```
   Where:
   - `<git-org>/<git-repo>` is the GitHub organization and repository name, formatted as code (surrounded by backticks)
   - `[<pr-title>](<pr-url>)` is the Markdown link format making the PR title clickable
   - Include a brief summary of the PR changes above the formatted line (1-2 sentences as necessary)

   Example format:

   Brief summary of changes here

   :git-pull-request: `my-org/my-repo` :github: [chore: upgrade to Node 24.x and Serverless 4.x](https://github.com/my-org/my-repo/pull/123)

   **Workflow:**
   - First, show the Slack message in plain text for user verification
   - If user approves, automatically copy it to clipboard using `pbcopy` (macOS) or `xclip` (Linux) WITHOUT asking for confirmation
   - Use a heredoc with the copy command to preserve exact formatting and prevent line breaks
   - Note: The clipboard copy command should not require user permission prompts

   **IMPORTANT:**
   - The formatted line with :git-pull-request: MUST be on a single continuous line with NO line breaks anywhere in it
   - Ensure the markdown link `[<pr-title>](<pr-url>)` stays intact on one line
   - If the summary is 2 sentences, put each sentence on a separate line (one sentence per line)

## MANDATORY: After PR is Closed/Merged
1. **Verify merge status and cleanup branches**:
   - **Step 1 - Verify PR was merged**: Use `gh pr view <pr-number> --json state,mergedAt` to confirm state is "MERGED"
   - **Step 2 - Verify feature branch was merged**: Check that the feature branch commits are in main/master
   - **Step 3 - Confirm safety**: Report to user that the branch has been merged and it's safe to delete
   - **Step 4 - Only if PR state is MERGED**: Proceed with branch cleanup
   - Switch to main/master branch
   - Run `git fetch origin` and pull latest changes from origin/main (or origin/master)
   - **Step 5 - Check and delete remote first**: Use `git ls-remote --heads origin <feature-branch>` to check if remote branch exists
   - **Only if remote exists**: Delete remotely with `git push origin --delete <feature-branch>`
   - **Step 6 - Delete local branch**: Delete the feature branch locally with `git branch -D <feature-branch>` (use -D since squashed commits won't show as merged)
2. **Add entry to daily journal**: Insert into `~/notes/Daily_Journal.txt` in chronological order
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
- Squashing commits
- Multi-step git operations (show the plan first)

## No Confirmation Needed For
- Running git fetch
- Creating feature branches
- Regular commits on feature branches
- Pushing commits to feature branches (including force-push after squashing)
- Checking git status or log
- Reading files or templates
- Read-only PR/issue commands (gh pr view, gh pr list, gh issue view, etc.)
