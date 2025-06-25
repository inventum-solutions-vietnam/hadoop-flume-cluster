#!/bin/bash

# Test script to send events to Flume HTTP source
# Usage: ./test-flume.sh [number_of_events]

FLUME_HOST="localhost"
FLUME_PORT="44444"
NUM_EVENTS=${1:-10}

echo "Sending $NUM_EVENTS events to Flume agent at $FLUME_HOST:$FLUME_PORT"

for i in $(seq 1 $NUM_EVENTS); do
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
    
    # Create event data as JSON
    event_json=$(cat <<EOF
{
    "timestamp": "$timestamp",
    "event_id": "event_$i",
    "message": "Test event number $i",
    "source": "test-script",
    "level": "INFO",
    "data": {
        "user_id": "user_$((RANDOM % 1000))",
        "action": "test_action",
        "value": $((RANDOM % 100))
    }
}
EOF
)
    
    # Base64 encode the event data
    event_body=$(echo "$event_json" | base64 -w 0)
    
    # Create Flume-compatible JSON format
    flume_event=$(cat <<EOF
[{
    "headers": {
        "timestamp": "$timestamp",
        "source": "test-script",
        "event_id": "event_$i"
    },
    "body": "$event_body"
}]
EOF
)
    
    echo "Sending event $i..."
    curl -X POST \
        -H "Content-Type: application/json" \
        -d "$flume_event" \
        "http://$FLUME_HOST:$FLUME_PORT"
    
    echo "Event $i sent successfully"
    sleep 1
done

echo "All $NUM_EVENTS events sent successfully!"
echo "Check HDFS for the events: hdfs dfs -ls /flume/events/" 