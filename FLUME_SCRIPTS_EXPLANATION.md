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

**Parameters**:
- `$1` (optional): Number of events to send (default: 10)

**What it does**:
1. Sets `FLUME_HOST="localhost"` and `FLUME_PORT="44444"`
2. Uses `NUM_EVENTS=${1:-10}` to get event count (defaults to 10 if no parameter)
3. Loops through events, generating:
   - Timestamp using `date -u +"%Y-%m-%dT%H:%M:%S.%3NZ"`
   - Random user_id: `user_$((RANDOM % 1000))`
   - Random value: `$((RANDOM % 100))`
4. Creates JSON event data
5. Base64 encodes the event: `echo "$event_json" | base64 -w 0`
6. Sends via `curl -X POST` to `http://$FLUME_HOST:$FLUME_PORT`
7. Waits 1 second between events: `sleep 1`

**Key Commands Used**:
- `date -u +"%Y-%m-%dT%H:%M:%S.%3NZ"`: Generate UTC timestamp
- `base64 -w 0`: Encode without line wrapping
- `curl -X POST -H "Content-Type: application/json"`: Send HTTP POST request

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

**Parameters**:
- `$1` (optional): Date in YYYY-MM-DD format (default: current UTC date)
- `$2` (optional): Hour in HH format (default: current UTC hour)

**What it does**:
1. Sets date and hour using UTC time: `date -u +%Y-%m-%d` and `date -u +%H`
2. Lists files in HDFS directory: `docker exec hadoop-master hdfs dfs -ls /flume/events/$DATE/$HOUR/`
3. Reads all event files: `docker exec hadoop-master hdfs dfs -cat /flume/events/$DATE/$HOUR/*.log*`
4. For each line, attempts to decode base64: `echo "$line" | base64 -d`
5. Pretty-prints JSON using `jq .` if valid JSON
6. Shows raw line if not valid base64/JSON

**Key Commands Used**:
- `date -u +%Y-%m-%d`: Get current UTC date
- `date -u +%H`: Get current UTC hour
- `docker exec hadoop-master hdfs dfs -ls`: List HDFS files
- `docker exec hadoop-master hdfs dfs -cat`: Read HDFS file content
- `base64 -d`: Decode base64 data
- `jq .`: Pretty-print JSON

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

**Parameters**: None

**What it does**:
1. **Container Check**: `docker ps | grep -q flume-agent`
   - Lists running containers and searches for flume-agent
   - Returns success if container is running

2. **HTTP Endpoint Check**: `curl -s -f http://localhost:44444`
   - `-s`: Silent mode (no progress bar)
   - `-f`: Fail silently on HTTP errors
   - Tests if Flume HTTP source is accessible

3. **Log Display**: `docker logs --tail 10 flume-agent`
   - Shows last 10 lines of Flume container logs
   - Helps identify startup issues or errors

4. **HDFS Connectivity**: `docker exec flume-agent hdfs dfsadmin -report -namenode hadoop-master:9000`
   - Tests if Flume can connect to HDFS NameNode
   - Verifies network connectivity between containers

5. **HDFS Directory Check**: `docker exec hadoop-master hdfs dfs -test -d /flume/events`
   - Tests if Flume directory exists in HDFS
   - Lists directory contents if it exists

**Key Commands Used**:
- `docker ps | grep -q`: Check if container is running
- `curl -s -f`: Test HTTP endpoint silently
- `docker logs --tail 10`: Show recent container logs
- `docker exec`: Execute commands inside containers
- `hdfs dfsadmin -report`: Get HDFS cluster report
- `hdfs dfs -test -d`: Test if HDFS directory exists

## Configuration

### `config/flume-agent.conf`
Flume agent configuration with:
- **HTTP Source**: Receives events on port 44444
- **Memory Channel**: Buffers 1000 events
- **HDFS Sink**: Writes to `/flume/events/YYYY-MM-DD/HH/`

**Key Configuration Parameters**:
```properties
# HTTP Source
http-to-hdfs-agent.sources.http-source.port = 44444
http-to-hdfs-agent.sources.http-source.bind = 0.0.0.0

# Memory Channel
http-to-hdfs-agent.channels.memory-channel.capacity = 1000
http-to-hdfs-agent.channels.memory-channel.transactionCapacity = 100

# HDFS Sink
http-to-hdfs-agent.sinks.hdfs-sink.hdfs.path = hdfs://hadoop-master:9000/flume/events/%Y-%m-%d/%H
http-to-hdfs-agent.sinks.hdfs-sink.hdfs.rollInterval = 300
http-to-hdfs-agent.sinks.hdfs-sink.hdfs.batchSize = 100
```

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

**Event Structure**:
- **headers**: Metadata about the event (timestamp, source, event_id)
- **body**: Base64-encoded JSON containing the actual event data
- **timestamp**: ISO 8601 format in UTC
- **source**: Identifies the origin of the event
- **event_id**: Unique identifier for the event

## Data Flow

```
HTTP POST → Flume HTTP Source → Memory Channel → HDFS Sink → HDFS
   ↓              ↓                    ↓              ↓
test-flume.sh   Port 44444        1000 events    /flume/events/
web-app         JSON Handler      Transaction    YYYY-MM-DD/HH/
                Base64 decode     100 events     events.log
```

**Flow Explanation**:
1. **HTTP POST**: Scripts send events via HTTP POST to port 44444
2. **HTTP Source**: Flume receives and parses JSON events
3. **Memory Channel**: Events are buffered in memory (1000 max, 100 per transaction)
4. **HDFS Sink**: Events are written to HDFS with time-based partitioning
5. **HDFS Storage**: Files are stored as `/flume/events/YYYY-MM-DD/HH/events.timestamp.log`

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