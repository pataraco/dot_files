# Git Workflow Instructions

When working in git repositories, follow this workflow:

## Before Making Changes
1. **Always fetch latest changes first**: Run `git fetch origin` and check if the current branch is behind `origin/main` or `origin/master`
2. **Sync with main**: If on main/master, pull latest changes. If on a feature branch, consider rebasing onto latest main/master
3. **Create/verify feature branch**: Ensure we're working on a feature branch, not main/master directly. Branch naming should reflect the actual changes being made (e.g., `feature/add-user-auth`, `fix/login-validation`, `refactor/api-endpoints`)

## Committing Changes
1. **Create meaningful commits** during development
2. **Before creating PR**: Rebase and squash all commits into a single commit with a clear message
3. **Command sequence**:
   - `git rebase -i origin/main` (or origin/master)
   - Squash all commits into one
   - Write clear commit message following conventional commits format

## Creating Pull Requests
1. **Always check for PR template**: Look for `.github/PULL_REQUEST_TEMPLATE.md` or `.github/pull_request_template.md`
2. **Use the template**: If found, structure the PR description according to the template
3. **Ask before pushing**: Confirm before pushing to remote or creating the PR

## Confirmation Points
- Confirm before: force-pushing, creating PR, squashing commits
- Always show the plan before executing multi-step git operations
