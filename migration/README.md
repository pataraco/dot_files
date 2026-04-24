# migration/

Auto-generated inventory files used by laptop migration. Regenerate with:

```bash
./migrate.sh refresh-manifest
```

## Files

| File              | Produced by                            | Purpose |
|-------------------|----------------------------------------|---------|
| `repos.txt`       | `git -C ... remote get-url origin`     | Re-clone `~/repos/**` on the new laptop |
| `mas.txt`         | `mas list`                             | Re-install App Store apps |
| `vscode.txt`      | `code --list-extensions --show-versions` | Re-install VS Code extensions |
| `cursor.txt`      | `cursor --list-extensions --show-versions` | Re-install Cursor extensions |

All files are plain text, one entry per line, safe to commit (they contain URLs and app IDs only — no credentials).
