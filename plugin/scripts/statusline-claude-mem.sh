#!/bin/bash
# Claude-mem status line for Claude Code
# Displays worker health and database stats

# ANSI color codes
GREEN='\033[32m'
YELLOW='\033[33m'
RESET='\033[0m'

# Query worker API with short timeout
RESPONSE=$(curl -s --max-time 0.3 http://localhost:37777/api/stats 2>/dev/null)

# Check if request succeeded
if [ $? -eq 0 ] && [ -n "$RESPONSE" ]; then
    # Parse JSON using jq
    OBS=$(echo "$RESPONSE" | jq -r '.database.observations // 0')
    SESSIONS=$(echo "$RESPONSE" | jq -r '.database.sessions // 0')

    # Display healthy status with green indicator
    echo -e "${GREEN}●${RESET} claude-mem: ${OBS} obs | ${SESSIONS} sessions"
else
    # Worker not responding with yellow warning
    echo -e "${YELLOW}⚠️${RESET} claude-mem"
fi
