# Apache Flume Simple Demo

A straightforward demo showing Flume data ingestion from HTTP to HDFS.

## Prerequisites

Ensure the Hadoop cluster and Flume are running:
```bash
./start-cluster.sh
```

## Demo Workflow

### Step 1: Check Flume Status
```bash
./check-flume.sh
```
**Expected**: All checks should show ✅ (green)

### Step 2: Send Test Events
```bash
./test-flume.sh 5
```
**Expected**: "All 5 events sent successfully!"

### Step 3: View Test Events
```bash
./view-flume-events.sh
```
**Expected**: Shows 5 decoded JSON events with test data

### Step 4: Test Web App Integration
```bash
# Start the web application
cd web-app
npm install
npm start
```

In another terminal, send events via the web app:
```bash
curl -X POST http://localhost:3000/api/events \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello from web app", "user": "demo_user"}'
```

### Step 5: View Web App Events
```bash
./view-flume-events.sh
```
**Expected**: Shows both test script events and web app events

## What You'll See

### Test Script Events
```json
{
  "timestamp": "2025-06-30T04:35:40.000Z",
  "event_id": "event_1",
  "message": "Test event number 1",
  "source": "test-script",
  "level": "INFO",
  "data": {
    "user_id": "user_275",
    "action": "test_action",
    "value": 29
  }
}
```

### Web App Events
```json
{
  "timestamp": "2025-06-30T04:38:15.000Z",
  "message": "Hello from web app",
  "user": "demo_user",
  "source": "web-app"
}
```

## Key Points

- **Time-based Partitioning**: Events are stored in HDFS by date and hour
- **UTC Time**: Flume uses UTC time for partitioning (not your local time)
- **Base64 Encoding**: Event bodies are base64-encoded for transmission
- **JSON Format**: All events follow a consistent JSON structure

## Troubleshooting

If you see "No events found":
1. Check if events were sent: `./check-flume.sh`
2. Verify the correct UTC hour: `date -u`
3. Try viewing a specific hour: `./view-flume-events.sh 2025-06-30 04`

## Next Steps

- Modify the web app to send different event types
- Explore HDFS data structure: `docker exec hadoop-master hdfs dfs -ls -R /flume/events/`
- Check Flume logs: `docker logs flume-agent` 