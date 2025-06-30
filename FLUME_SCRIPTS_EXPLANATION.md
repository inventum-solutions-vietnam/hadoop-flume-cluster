# Apache Flume Scripts - Compact Guide

This document explains the Flume scripts in this repository for data ingestion from HTTP to HDFS.

## Core Scripts

### 1. `test-flume.sh`
**Purpose**: Send test events to Flume HTTP source
- Generates realistic JSON events with timestamps
- Sends events via HTTP POST to Flume (port 44444)
- Supports configurable number of events

**Usage**:
```bash
./test-flume.sh          # Send 10 events (default)
./test-flume.sh 20       # Send 20 events
```

### 2. `view-flume-events.sh`
**Purpose**: View and decode Flume events from HDFS
- Lists event files for specific date/hour
- Decodes base64-encoded event data
- Pretty-prints JSON events

**Usage**:
```bash
./view-flume-events.sh                    # View current UTC hour events
./view-flume-events.sh 2025-06-30 04     # View specific date/hour
```

### 3. `check-flume.sh`
**Purpose**: Health check for Flume setup
- Verifies Flume container is running
- Tests HTTP endpoint accessibility
- Shows recent Flume logs
- Validates HDFS connectivity

**Usage**:
```bash
./check-flume.sh
```

## Configuration

### `config/flume-agent.conf`
Flume agent configuration with:
- **HTTP Source**: Receives events on port 44444
- **Memory Channel**: Buffers 1000 events
- **HDFS Sink**: Writes to `/flume/events/YYYY-MM-DD/HH/`

## Event Format

Events are sent as JSON with headers and base64-encoded body:
```json
[{
  "headers": {
    "timestamp": "2025-06-30T04:35:40.000Z",
    "source": "test-script",
    "event_id": "event_1"
  },
  "body": "base64_encoded_json_data"
}]
```

## Data Flow

```
HTTP POST → Flume HTTP Source → Memory Channel → HDFS Sink → HDFS
   ↓              ↓                    ↓              ↓
test-flume.sh   Port 44444        1000 events    /flume/events/
web-app         JSON Handler      Transaction    YYYY-MM-DD/HH/
                Base64 decode     100 events     events.log
```

## Quick Commands

```bash
# Check Flume status
./check-flume.sh

# Send test events
./test-flume.sh 5

# View latest events
./view-flume-events.sh

# View specific events
./view-flume-events.sh 2025-06-30 04
```

## Troubleshooting

- **No events found**: Check if events were sent to the correct UTC hour
- **HTTP endpoint not accessible**: Restart Flume container
- **HDFS connectivity issues**: Ensure Hadoop cluster is running 