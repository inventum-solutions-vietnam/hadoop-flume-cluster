# Apache Flume Integration with Hadoop Cluster

This document describes the Apache Flume integration that has been added to your Hadoop cluster. The Flume agent receives events via HTTP source and aggregates them to HDFS.

## Architecture

```
HTTP Clients → Flume HTTP Source → Memory Channel → HDFS Sink → HDFS
```

## Components

### Flume Agent Configuration
- **Source**: HTTP source listening on port 44444
- **Channel**: Memory channel with 1000 event capacity
- **Sink**: HDFS sink writing to `/flume/events/YYYY-MM-DD/HH/` directory structure

### File Structure
```
config/
├── flume-agent.conf    # Flume agent configuration
└── start-flume.sh      # Script to start Flume agent

test-flume.sh           # Test script to send events to Flume
```

## Usage

### 1. Start the Cluster with Flume

```bash
# Build and start all services including Flume
./start-cluster.sh

# Or use docker-compose directly
docker-compose up -d
```

### 2. Check Flume Status

```bash
# Check if Flume container is running
docker ps | grep flume-agent

# Check Flume logs
docker logs flume-agent

# Check Flume health
docker exec flume-agent curl -f http://localhost:44444
```

### 3. Send Test Events

```bash
# Send 10 test events (default)
./test-flume.sh

# Send specific number of events
./test-flume.sh 50
```

### 4. Verify Events in HDFS

```bash
# List events in HDFS
docker exec hadoop-master hdfs dfs -ls /flume/events/

# View specific event files
docker exec hadoop-master hdfs dfs -cat /flume/events/2024-01-15/14/events.1705320000000.log
```

## Configuration Details

### Flume Agent Configuration (`config/flume-agent.conf`)

- **HTTP Source**: 
  - Port: 44444
  - Handler: JSONHandler for JSON events
  - Bind: 0.0.0.0 (all interfaces)

- **Memory Channel**:
  - Capacity: 1000 events
  - Transaction Capacity: 100 events

- **HDFS Sink**:
  - Path: `hdfs://hadoop-master:9000/flume/events/%Y-%m-%d/%H`
  - File prefix: `events`
  - File suffix: `.log`
  - Roll interval: 300 seconds (5 minutes)
  - Batch size: 100 events

### Event Format

The Flume agent expects events in a specific JSON format with headers and base64-encoded body. Example:

```json
[
  {
    "headers": {
      "timestamp": "2024-01-15T14:30:00.000Z",
      "source": "application-name",
      "event_id": "event_123"
    },
    "body": "eyJ0aW1lc3RhbXAiOiAiMjAyNC0wMS0xNVQxNDozMDowMC4wMDBaIiwgImV2ZW50X2lkIjogImV2ZW50XzEyMyIsICJtZXNzYWdlIjogIlNhbXBsZSBldmVudCBtZXNzYWdlIiwgInNvdXJjZSI6ICJhcHBsaWNhdGlvbi1uYW1lIiwgImxldmVsIjogIklORk8iLCAiZGF0YSI6IHsidXNlcl9pZCI6ICJ1c2VyXzQ1NiIsICJhY3Rpb24iOiAibG9naW4iLCAidmFsdWUiOiA0Mn19"
  }
]
```

The `body` field contains the base64-encoded JSON event data. The original event data should be:

```json
{
    "timestamp": "2024-01-15T14:30:00.000Z",
    "event_id": "event_123",
    "message": "Sample event message",
    "source": "application-name",
    "level": "INFO",
    "data": {
        "user_id": "user_456",
        "action": "login",
        "value": 42
    }
}
```

## API Usage

### Send Events via HTTP

```bash
# Send a single event
curl -X POST \
  -H "Content-Type: application/json" \
  -d '[
    {
      "headers": {
        "timestamp": "'$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")'",
        "source": "web-app",
        "event_id": "event_001"
      },
      "body": "'$(echo '{"timestamp":"'$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")'","event_id":"event_001","message":"User login event","source":"web-app","level":"INFO","data":{"user_id":"user_123","action":"login","ip_address":"192.168.1.100"}}' | base64 -w 0)'"
    }
  ]' \
  http://localhost:44444
```

### Programmatic Usage

```python
import requests
import json
import base64
from datetime import datetime

def send_flume_event(event_data):
    url = "http://localhost:44444"
    headers = {"Content-Type": "application/json"}
    
    # Add timestamp if not present
    if "timestamp" not in event_data:
        event_data["timestamp"] = datetime.utcnow().isoformat() + "Z"
    
    # Create Flume-compatible format
    flume_event = [{
        "headers": {
            "timestamp": event_data["timestamp"],
            "source": event_data.get("source", "python-app"),
            "event_id": event_data.get("event_id", "unknown")
        },
        "body": base64.b64encode(json.dumps(event_data).encode()).decode()
    }]
    
    response = requests.post(url, json=flume_event, headers=headers)
    return response.status_code == 200

# Example usage
event = {
    "event_id": "user_action_001",
    "message": "User clicked button",
    "source": "frontend",
    "level": "INFO",
    "data": {
        "user_id": "user_456",
        "action": "button_click",
        "button_id": "submit_form"
    }
}

success = send_flume_event(event)
print(f"Event sent successfully: {success}")
```

## Monitoring and Troubleshooting

### Check Flume Logs

```bash
# View Flume logs
docker logs flume-agent

# Follow Flume logs in real-time
docker logs -f flume-agent
```

### Check HDFS Status

```bash
# Check HDFS health
docker exec hadoop-master hdfs dfsadmin -report

# Check available space
docker exec hadoop-master hdfs dfs -df
```

### Common Issues

1. **Flume not starting**: Check if HDFS is ready
   ```bash
   docker exec hadoop-master hdfs dfsadmin -report
   ```

2. **Events not reaching HDFS**: Check Flume logs
   ```bash
   docker logs flume-agent
   ```

3. **Port conflicts**: Ensure port 44444 is available
   ```bash
   netstat -an | grep 44444
   ```

## Scaling

To scale the Flume agent or add multiple agents:

1. **Multiple Flume Agents**: Add additional services in `docker-compose.yml`
2. **Load Balancing**: Use a load balancer (nginx, haproxy) in front of multiple Flume agents
3. **High Availability**: Deploy Flume agents on different hosts

## Performance Tuning

### Memory Channel Tuning
- Increase `capacity` for higher throughput
- Adjust `transactionCapacity` based on batch size

### HDFS Sink Tuning
- Adjust `rollInterval` for file rotation frequency
- Modify `batchSize` for optimal write performance
- Consider using `SequenceFile` format for better compression

### Example Optimized Configuration
```properties
# For high-throughput scenarios
http-to-hdfs-agent.channels.memory-channel.capacity = 10000
http-to-hdfs-agent.channels.memory-channel.transactionCapacity = 1000
http-to-hdfs-agent.sinks.hdfs-sink.hdfs.batchSize = 1000
http-to-hdfs-agent.sinks.hdfs-sink.hdfs.rollInterval = 600
```

## Security Considerations

1. **Network Security**: Consider using HTTPS for the HTTP source
2. **Authentication**: Implement authentication for the HTTP endpoint
3. **Data Encryption**: Enable HDFS encryption for sensitive data
4. **Access Control**: Configure HDFS permissions for the flume directory

## Integration with Other Tools

### Apache Kafka Integration
Replace HTTP source with Kafka source for high-throughput scenarios:

```properties
http-to-hdfs-agent.sources.kafka-source.type = org.apache.flume.source.kafka.KafkaSource
http-to-hdfs-agent.sources.kafka-source.kafka.bootstrap.servers = kafka:9092
http-to-hdfs-agent.sources.kafka-source.kafka.topics = events-topic
```

### Elasticsearch Integration
Add Elasticsearch sink for real-time search:

```properties
http-to-hdfs-agent.sinks.es-sink.type = org.apache.flume.sink.elasticsearch.ElasticSearchSink
http-to-hdfs-agent.sinks.es-sink.hostNames = elasticsearch:9200
http-to-hdfs-agent.sinks.es-sink.indexName = flume-events
``` 