#!/bin/bash

# Script to view and decode Flume events from HDFS
# Usage: ./view-flume-events.sh [date] [hour]

# If no arguments, use current UTC date and hour
if [ -z "$1" ]; then
  DATE=$(date -u +%Y-%m-%d)
else
  DATE=$1
fi
if [ -z "$2" ]; then
  HOUR=$(date -u +%H)
else
  HOUR=$2
fi

echo "=== Viewing Flume Events for $DATE/$HOUR ==="

# List files in the directory
echo "Files in /flume/events/$DATE/$HOUR/:"
docker exec hadoop-master hdfs dfs -ls /flume/events/$DATE/$HOUR/ 2>/dev/null || {
    echo "No events found for $DATE/$HOUR"
    exit 1
}

echo ""
echo "=== Event Contents ==="

# Get all event files and decode them
docker exec hadoop-master hdfs dfs -cat /flume/events/$DATE/$HOUR/*.log* 2>/dev/null | while IFS= read -r line; do
    # Skip empty lines and warnings
    if [[ -n "$line" && ! "$line" =~ WARN.*NativeCodeLoader ]]; then
        # Try to decode as base64
        if echo "$line" | base64 -d 2>/dev/null | jq . >/dev/null 2>&1; then
            echo "--- Decoded Event ---"
            echo "$line" | base64 -d | jq .
            echo ""
        else
            # If not valid base64, just show the raw line
            echo "--- Raw Event ---"
            echo "$line"
            echo ""
        fi
    fi
done

echo "=== End of Events ===" 