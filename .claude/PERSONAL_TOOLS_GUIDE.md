# Personal Tools Setup Guide

**TL;DR:** Your personal development tools live in `.claude/` and are **invisible to git** but always available when you work.

---

## What's Set Up

### Personal Tools (Always Available, Never Committed)
- **`.claude/skills/multi-agent-composition/`** - Core 4 framework, composition patterns, architectural guidance
- **`.claude/commands/review-pr-msg.md`** - Maintainer-perspective PR review command

### How It Works
- **Files exist** in your working directory
- **Git ignores them** via `.git/info/exclude` (like `.gitignore` but not committed)
- **Never show up** in `git status`, commits, or PRs
- **Backed up** on your fork in `personal-tools-backup` branch

---

## Daily Workflow

### Working on Contributions (Normal Day)
```bash
# Your tools are always there, git just ignores them
git checkout -b fix/some-bug
# Use your skills/commands while working
git add .
git commit -m "fix: whatever"
git push origin fix/some-bug
# Tools never get committed ✓
```

### Syncing with Upstream
```bash
git checkout main
git fetch upstream
git merge upstream/main
git push origin main
# Your tools are still there after sync ✓
```

### Creating PRs
```bash
# Your tools are present but excluded from commits
git status  # Won't show .claude/skills or .claude/commands
# PR will be clean, no personal tools included ✓
```

---

## If You Lose Your Tools (Restore from Backup)

```bash
# 1. Get files from backup branch
git checkout personal-tools-backup -- .claude/

# 2. Unstage them (so they stay ignored)
git reset HEAD .claude/

# 3. Verify
ls .claude/commands/review-pr-msg.md  # Should exist
git status  # Should NOT show .claude/ files
```

---

## Adding New Personal Tools

```bash
# 1. Add the new tool file
echo "some new tool" > .claude/commands/my-new-tool.md

# 2. Add to exclusion list
echo ".claude/commands/my-new-tool.md" >> .git/info/exclude

# 3. Back it up
git checkout personal-tools-backup
git add .claude/commands/my-new-tool.md
git commit -m "Personal: Add my-new-tool"
git push origin personal-tools-backup
git checkout main

# 4. Restore it to working directory
git checkout personal-tools-backup -- .claude/commands/my-new-tool.md
git reset HEAD .claude/commands/my-new-tool.md

# Now it's ignored, backed up, and available
```

---

## Quick Reference Commands

### Check What's Excluded
```bash
cat .git/info/exclude
# Should show:
# .claude/skills/multi-agent-composition/
# .claude/commands/review-pr-msg.md
```

### Verify Tools Are There But Ignored
```bash
# Files exist
ls .claude/commands/review-pr-msg.md  # ✓ Found

# Git ignores them
git status --short  # .claude/ files won't appear
```

### View Backup Branch
```bash
# See what's backed up
git show personal-tools-backup:.claude/commands/review-pr-msg.md

# Or browse on GitHub
# https://github.com/basher83/claude-mem/tree/personal-tools-backup
```

---

## Troubleshooting

### "My tools disappeared!"
**Cause:** You switched branches and files weren't in working directory.
**Fix:**
```bash
git checkout personal-tools-backup -- .claude/
git reset HEAD .claude/
```

### "Git is trying to commit my tools!"
**Cause:** Files got staged somehow.
**Fix:**
```bash
git reset HEAD .claude/  # Unstage
git status  # Should not show .claude/ anymore
```

### "I want to update my backed-up tools"
```bash
# 1. Make changes to your tools in .claude/
# 2. Update backup
git checkout personal-tools-backup
git add .claude/
git commit -m "Personal: Update tools"
git push origin personal-tools-backup
git checkout main
```

---

## What NOT To Do

❌ **Don't add `.claude/` to `.gitignore`** - That would commit the ignore rule, affecting everyone

❌ **Don't commit personal tools to main** - They're personal, not for upstream

❌ **Don't delete personal-tools-backup branch** - That's your safety net

✅ **Do keep tools in `.git/info/exclude`** - Local exclusion, doesn't affect others

✅ **Do back up changes to personal-tools-backup** - Keeps your tools safe

✅ **Do branch from main for contributions** - Clean start without tools in commits

---

## Understanding the Setup

### Three Levels of Your Fork

```
1. main (clean, synced with upstream)
   └── git ignores .claude/ via .git/info/exclude
   └── Files exist in working directory but invisible to git

2. personal-tools-backup (backup copy of tools)
   └── Contains committed versions of all personal tools
   └── Safe on GitHub, can restore anytime

3. feature branches (clean contributions)
   └── Branch from main
   └── Tools present but never committed (inherited ignore rules)
```

### Files vs Git Status

```
Working Directory:
├── .claude/
│   ├── commands/
│   │   └── review-pr-msg.md          ← EXISTS, you can use it
│   └── skills/
│       └── multi-agent-composition/  ← EXISTS, you can use it

Git Status:
(empty - git doesn't see these files)

Backup Branch:
personal-tools-backup contains committed copies
```

---

## Why This Works

**Problem:** Need personal tools available but not in PRs
**Solution:**
- `.git/info/exclude` = Git ignores files locally (not committed ignore rule)
- `personal-tools-backup` = Safety backup on your fork
- Files stay in working directory = Always available

**Result:**
- ✅ Tools always available when you work
- ✅ Never show up in git status
- ✅ Never accidentally committed
- ✅ Backed up safely on your fork
- ✅ Sync with upstream without conflicts

---

## One-Liners for Tomorrow You

```bash
# Lost tools? Restore:
git checkout personal-tools-backup -- .claude/ && git reset HEAD .claude/

# Check if tools are there:
ls .claude/commands/*.md .claude/skills/*/SKILL.md

# Verify git ignores them:
git status | grep -q ".claude" && echo "ERROR: git sees .claude/" || echo "✓ git ignores .claude/"

# Update backup:
git checkout personal-tools-backup && git add .claude/ && git commit -m "Personal: Update" && git push origin personal-tools-backup && git checkout main
```

---

## Summary

You're set up! Your personal development tools are:
- 📁 **Always in** `.claude/` directory
- 👻 **Invisible to** git (via `.git/info/exclude`)
- 💾 **Backed up** in `personal-tools-backup` branch
- 🚫 **Never committed** to contribution PRs
- 🔄 **Survive** upstream syncs

**Just work normally** - git handles the rest!
