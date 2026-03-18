#!/usr/bin/env bash

# This script is called by the Gemini CLI SessionEnd hook.
# It appends the current session's summary to PROGRESS.md if it exists.

SUMMARY_FILE=".gemini/tmp/current_session_summary.md"
PROGRESS_FILE="PROGRESS.md"

if [ -f "$SUMMARY_FILE" ]; then
    echo -e "\n---\n" >> "$PROGRESS_FILE"
    echo "### Session Summary ($(date))" >> "$PROGRESS_FILE"
    cat "$SUMMARY_FILE" >> "$PROGRESS_FILE"
    rm "$SUMMARY_FILE"
fi

# Always return empty JSON to satisfy hook requirement
echo "{}"
