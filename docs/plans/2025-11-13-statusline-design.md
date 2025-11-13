# Status Line for Claude-Mem

**Date:** 2025-11-13
**Purpose:** Add status line to Claude Code showing claude-mem worker health and stats
**Problem:** Users in Codespaces (or restricted environments) cannot access web UI at localhost:37777, leaving them with zero visibility into whether claude-mem is working.

---

## Problem Statement

When working from Codespaces or environments with HTTP restrictions, users cannot access the web UI viewer. They have no way to know if:
- Worker is running
- Observations are being captured
- System is healthy

Terminal floods with errors when worker is down, but provides no feedback when everything is working correctly.

---

## Solution

Create a status line script that displays claude-mem health and stats at the bottom of Claude Code interface.

**Display format:**
- **Healthy:** `● claude-mem: 52 obs | 7 sessions`
- **Unhealthy:** `⚠️ claude-mem`

**Updates:** Every 300ms (automatic via Claude Code status line system)

---

## Design

### Architecture

```
Claude Code Status Line System
        ↓
~/.claude/statusline-claude-mem.sh
        ↓
HTTP GET http://localhost:37777/api/stats
        ↓
Parse JSON response
        ↓
Format and echo to stdout
```

### Status Line Script

**File:** `~/.claude/statusline-claude-mem.sh`

**Responsibilities:**
1. Query worker API for stats
2. Format response for display
3. Handle errors gracefully (show warning icon)
4. Keep output concise (one line)

**Implementation:**
```bash
#!/bin/bash
# Claude-mem status line for Claude Code
# Displays worker health and database stats

# Query worker API with short timeout
RESPONSE=$(curl -s --max-time 0.3 http://localhost:37777/api/stats 2>/dev/null)

# Check if request succeeded
if [ $? -eq 0 ] && [ -n "$RESPONSE" ]; then
    # Parse JSON using jq
    OBS=$(echo "$RESPONSE" | jq -r '.database.observations // 0')
    SESSIONS=$(echo "$RESPONSE" | jq -r '.database.sessions // 0')

    # Display healthy status
    echo "● claude-mem: ${OBS} obs | ${SESSIONS} sessions"
else
    # Worker not responding
    echo "⚠️ claude-mem"
fi
```

### Configuration

**User adds to `~/.claude/settings.json`:**

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline-claude-mem.sh",
    "padding": 0
  }
}
```

**Or runs:** `/statusline` and asks Claude Code to set it up.

---

## API Contract

### Endpoint: GET /api/stats

**Already exists** - no changes needed.

**Response:**
```json
{
  "worker": {
    "version": "5.5.1",
    "uptime": 12345,
    "activeSessions": 1,
    "sseClients": 0,
    "port": 37777
  },
  "database": {
    "path": "/home/user/.claude-mem/claude-mem.db",
    "size": 716800,
    "observations": 52,
    "sessions": 7,
    "summaries": 3
  }
}
```

**What we use:**
- `database.observations` - Total observations across all sessions
- `database.sessions` - Total sessions in database

---

## Error Handling

### Worker Down
- Curl timeout (0.3s) prevents hanging
- Script shows `⚠️ claude-mem`
- No blocking, no delays

### Invalid JSON
- `jq` falls back to `0` via `// 0` operator
- Display shows zeros instead of crashing

### Missing Dependencies
- Script requires: `curl`, `jq`
- Both are standard on most systems
- Installation instructions in README if needed

---

## Performance

### Request Speed
- Curl timeout: 300ms max
- API response: ~10-50ms typical
- Status line updates: Every 300ms (Claude Code limit)

**Impact:** Negligible - one fast HTTP request every 300ms.

### Worker Load
- Single GET request, read-only
- No database writes
- Returns cached stats (3 SQL COUNT queries)

**Impact:** Minimal - same as web UI stats refresh.

---

## Future Enhancements (Not in Scope)

### Out of Scope for v1:
- Per-session stats (would require new API endpoint)
- Activity indicator (capturing vs idle state)
- Custom color coding (ANSI colors - possible but not needed for v1)
- Click actions (not supported by Claude Code status line)

### Possible Future v2:
- Add `/api/stats/current` endpoint for per-session data
- Show "capturing" indicator when save-hook is processing
- Display errors count or warnings
- Version mismatch detection (plugin vs worker version)

---

## Testing Plan

### Manual Testing
1. **Worker running:** Verify displays `● claude-mem: N obs | M sessions`
2. **Worker stopped:** Stop PM2, verify displays `⚠️ claude-mem`
3. **Worker restart:** Restart worker, verify stats update
4. **Codespaces:** Test in restricted environment (primary use case)

### Validation
- Check status line appears in Claude Code UI
- Verify stats match web UI (when accessible)
- Confirm no delays or hanging
- Test with slow network (curl timeout works)

---

## Installation

### For Plugin Users

**Option 1: Auto-setup**
```bash
/statusline
# Then tell Claude: "Show claude-mem status with observation and session counts"
```

**Option 2: Manual setup**
```bash
# 1. Create status line script
cat > ~/.claude/statusline-claude-mem.sh << 'EOF'
#!/bin/bash
RESPONSE=$(curl -s --max-time 0.3 http://localhost:37777/api/stats 2>/dev/null)
if [ $? -eq 0 ] && [ -n "$RESPONSE" ]; then
    OBS=$(echo "$RESPONSE" | jq -r '.database.observations // 0')
    SESSIONS=$(echo "$RESPONSE" | jq -r '.database.sessions // 0')
    echo "● claude-mem: ${OBS} obs | ${SESSIONS} sessions"
else
    echo "⚠️ claude-mem"
fi
EOF

# 2. Make executable
chmod +x ~/.claude/statusline-claude-mem.sh

# 3. Add to settings.json
# Edit ~/.claude/settings.json and add:
# "statusLine": {
#   "type": "command",
#   "command": "~/.claude/statusline-claude-mem.sh"
# }
```

---

## Dependencies

### Required
- `curl` - HTTP requests
- `jq` - JSON parsing

### Installation
**Ubuntu/Debian:**
```bash
sudo apt-get install curl jq
```

**macOS:**
```bash
brew install curl jq
```

**Windows (WSL):**
```bash
sudo apt-get install curl jq
```

---

## Success Criteria

✅ Status line shows `●` when worker is healthy
✅ Status line shows `⚠️` when worker is down
✅ Observation count matches `/api/stats`
✅ Session count matches `/api/stats`
✅ No performance impact (< 300ms response)
✅ Works in Codespaces (HTTP restrictions)
✅ Graceful failure (no blocking, no errors in terminal)

---

## Non-Goals

❌ Real-time "capturing" indicator (requires worker changes)
❌ Per-session stats (requires new API endpoint)
❌ Version mismatch detection (future enhancement)
❌ Click-to-restart functionality (not supported by status line)
❌ Auto-restart worker on error (separate feature)

---

## Documentation Updates

### README.md
Add section:
```markdown
### Status Line

See claude-mem health at a glance in Claude Code's status line.

**Setup:**
Run `/statusline` and tell Claude: "Show claude-mem status with observation and session counts"

**What you'll see:**
- `● claude-mem: 52 obs | 7 sessions` - Worker is healthy
- `⚠️ claude-mem` - Worker is not responding

**Useful in:** Codespaces, remote environments, or when web UI is not accessible.
```

### Plugin Skill/Command
Create `/claude-mem-status` slash command that explains how to set up status line.

---

## Implementation Checklist

- [ ] Create `~/.claude/statusline-claude-mem.sh` script
- [ ] Test with worker running
- [ ] Test with worker stopped
- [ ] Test in Codespaces environment
- [ ] Add installation instructions to README
- [ ] Create setup command or skill (optional)
- [ ] Document in user guide
