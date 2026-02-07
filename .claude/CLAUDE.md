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
4. **After PR creation or update**: Display summary in this exact format:
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
