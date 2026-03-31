# Git Repos Sync Instructions (GitHub ← ADO)

Steps for syncing a GitHub repository from Azure DevOps (ADO).
Working directory: the **GitHub repo** (the one being updated).

---

## Option A — GitHub repo not cloned yet

```shell
# Clone the GitHub repo
git clone git@git.example.com:my-org/my-repo.git
cd my-repo
```

## Option B — GitHub repo already cloned

```shell
# Ensure on main branch
git checkout main

# Verify working tree is clean
git status

# Fetch latest changes from GitHub
git fetch --prune origin

# Reset main to match origin/main
git reset --hard origin/main
```

---

## Sync Steps

```shell
# Check current git remotes
git remote -v

# Add Azure DevOps (ADO) as a remote named "ado" (if not already added)
git remote add ado git@ssh.dev.azure.com:v3/my-org/global/my-repo

# Fetch all branches from ADO
git fetch ado

# Check current commit history
git log --oneline --graph -10

# IMPORTANT: Create a backup branch with today's date
git branch backup-$(date +%d%b%Y)

# View full history before rebasing
git log --oneline --graph --all --decorate -20

# Show commits unique to main (GitHub)
git log --oneline $(git merge-base main ado/develop)..main

# Show commits unique to ado/develop (ADO)
git log --oneline $(git merge-base main ado/develop)..ado/develop

# Rebase main (GitHub's commits) on top of ado/develop (ADO's commits)
git rebase ado/develop
```

---

## Resolving Conflicts

**The user resolves all conflicts themselves.** Do not attempt to resolve conflicts automatically.

When a conflict occurs, show the user what is conflicting and offer suggestions — but wait for them to decide and act. Useful context to provide:

- Which file(s) are conflicting
- What the ADO version contains vs. the GitHub version
- Which resolution strategy likely makes sense given the context (but let the user choose)

The available resolution strategies for reference:

```shell
# A. Get both updates — edit and manually pick/choose changes
vi path/to/CONFLICTING_FILE

# B. Keep only the ADO changes
git checkout --ours path/to/CONFLICTING_FILE

# C. Keep only the GitHub changes
git checkout --theirs path/to/CONFLICTING_FILE

# D. Delete a file that was deleted in ADO
git rm deleted_file
```

Once the user has resolved a conflict, run the following on their behalf:

```shell
# Stage the resolved file
git add path/to/CONFLICTING_FILE

# Continue the rebase
git rebase --continue

# Repeat until rebase completes
```

---

## Finish & Push

```shell
# Verify the rebased history looks correct
git log --oneline --graph --all --decorate -20

# Force push to origin/main (safer than --force)
git push origin main --force-with-lease
```

---

## Undo / Recovery

```shell
# Abort the rebase and return to original state (during rebase)
git rebase --abort

# Undo a completed rebase using the backup branch
git reset --hard backup-$(date +%d%b%Y)
```
