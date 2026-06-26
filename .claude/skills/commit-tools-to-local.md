---
name: commit-tools-to-local
description: Reminds the user to commit tools/ script changes to the fork-local branch, then returns to main
metadata:
  type: reminder
---

The `tools/` scripts (run-mac.sh, deploy.sh, etc.) are tracked only on the `local` branch — not on `main` or any feature branch — so they never appear in upstream PRs.

After editing a file under `tools/`, commit it there:

```bash
git stash           # if you have other uncommitted work
git checkout local
git add -f tools/
git commit -m "chore: update local dev scripts"
git checkout main
git stash pop       # if you stashed
```

The `-f` flag is required because `tools/` is listed in `.git/info/exclude` (which keeps it invisible as untracked on main/feature branches).
