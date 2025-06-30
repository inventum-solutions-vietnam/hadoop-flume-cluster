# Apache Flume Configuration Guide

This document explains the Flume agent configuration file and provides suggestions for experimentation.

## Configuration File: `config/flume-agent.conf`

The Flume configuration defines a complete data pipeline from HTTP source to HDFS sink.

## Agent Definition

```properties
# Define the agent
http-to-hdfs-agent.sources = http-source
http-to-hdfs-agent.channels = memory-channel
http-to-hdfs-agent.sinks = hdfs-sink
```

**What it does**: Defines the agent name and its three main components
- **Agent Name**: `http-to-hdfs-agent` (used when starting Flume)
- **Sources**: `http-source` (receives data)
- **Channels**: `memory-channel` (buffers data)
- **Sinks**: `hdfs-sink` (stores data)

## HTTP Source Configuration

```properties
# Configure HTTP Source
http-to-hdfs-agent.sources.http-source.type = org.apache.flume.source.http.HTTPSource
http-to-hdfs-agent.sources.http-source.port = 44444
http-to-hdfs-agent.sources.http-source.bind = 0.0.0.0
http-to-hdfs-agent.sources.http-source.handler.nickname = flume-http
```

### Parameters Explained

| Parameter | Value | Purpose | Tinkering Options |
|-----------|-------|---------|-------------------|
| `type` | `org.apache.flume.source.http.HTTPSource` | HTTP source implementation | Try other sources: `exec`, `spooldir`, `syslogtcp` |
| `port` | `44444` | HTTP listening port | Change to any available port (e.g., `8080`, `9000`) |
| `bind` | `0.0.0.0` | Bind to all network interfaces | Use `127.0.0.1` for local-only access |
| `handler.nickname` | `flume-http` | Handler identifier | Optional identifier for logging |

### HTTP Source Tinkering Ideas

1. **Change Port**: 
   ```properties
   http-to-hdfs-agent.sources.http-source.port = 8080
   ```

2. **Add Authentication** (if supported):
   ```properties
   http-to-hdfs-agent.sources.http-source.handler = org.apache.flume.source.http.JSONHandler
   ```

3. **Add Interceptors**:
   ```properties
   http-to-hdfs-agent.sources.http-source.interceptors = timestamp host
   http-to-hdfs-agent.sources.http-source.interceptors.timestamp.type = timestamp
   http-to-hdfs-agent.sources.http-source.interceptors.host.type = host
   ```

## Memory Channel Configuration

```properties
# Configure Memory Channel
http-to-hdfs-agent.channels.memory-channel.type = memory
http-to-hdfs-agent.channels.memory-channel.capacity = 1000
http-to-hdfs-agent.channels.memory-channel.transactionCapacity = 100
```

### Parameters Explained

| Parameter | Value | Purpose | Tinkering Options |
|-----------|-------|---------|-------------------|
| `type` | `memory` | In-memory channel implementation | Try `file` for persistence, `kafka` for streaming |
| `capacity` | `1000` | Maximum events in channel | Increase for high throughput, decrease for memory usage |
| `transactionCapacity` | `100` | Events per transaction | Should be ≤ capacity, affects performance |

### Memory Channel Tinkering Ideas

1. **Increase Capacity for High Throughput**:
   ```properties
   http-to-hdfs-agent.channels.memory-channel.capacity = 5000
   http-to-hdfs-agent.channels.memory-channel.transactionCapacity = 500
   ```

2. **Switch to File Channel for Reliability**:
   ```properties
   http-to-hdfs-agent.channels.memory-channel.type = file
   http-to-hdfs-agent.channels.memory-channel.checkpointDir = /tmp/flume/checkpoint
   http-to-hdfs-agent.channels.memory-channel.dataDirs = /tmp/flume/data
   http-to-hdfs-agent.channels.memory-channel.capacity = 10000
   ```

3. **Add Channel Selector**:
   ```properties
   http-to-hdfs-agent.sources.http-source.selector.type = replicating
   http-to-hdfs-agent.sources.http-source.channels = memory-channel file-channel
   ```

## HDFS Sink Configuration

```properties
# Configure HDFS Sink
http-to-hdfs-agent.sinks.hdfs-sink.type = hdfs
http-to-hdfs-agent.sinks.hdfs-sink.hdfs.path = hdfs://hadoop-master:9000/flume/events/%Y-%m-%d/%H
http-to-hdfs-agent.sinks.hdfs-sink.hdfs.filePrefix = events
http-to-hdfs-agent.sinks.hdfs-sink.hdfs.fileSuffix = .log
http-to-hdfs-agent.sinks.hdfs-sink.hdfs.rollInterval = 300
http-to-hdfs-agent.sinks.hdfs-sink.hdfs.rollSize = 0
http-to-hdfs-agent.sinks.hdfs-sink.hdfs.rollCount = 0
http-to-hdfs-agent.sinks.hdfs-sink.hdfs.fileType = DataStream
http-to-hdfs-agent.sinks.hdfs-sink.hdfs.writeFormat = Text
http-to-hdfs-agent.sinks.hdfs-sink.hdfs.batchSize = 100
http-to-hdfs-agent.sinks.hdfs-sink.hdfs.useLocalTimeStamp = true
```

### Parameters Explained

| Parameter | Value | Purpose | Tinkering Options |
|-----------|-------|---------|-------------------|
| `type` | `hdfs` | HDFS sink implementation | Try `file_roll`, `logger`, `elasticsearch` |
| `hdfs.path` | `hdfs://hadoop-master:9000/flume/events/%Y-%m-%d/%H` | HDFS storage path | Change partitioning, add more time components |
| `hdfs.filePrefix` | `events` | File name prefix | Use descriptive names like `user-events`, `logs` |
| `hdfs.fileSuffix` | `.log` | File extension | Use `.json`, `.txt`, `.avro` |
| `hdfs.rollInterval` | `300` | Roll file every 300 seconds (5 min) | Decrease for more frequent files, increase for larger files |
| `hdfs.rollSize` | `0` | Roll file at size (0 = disabled) | Set to bytes (e.g., `1048576` for 1MB) |
| `hdfs.rollCount` | `0` | Roll file after N events (0 = disabled) | Set to number (e.g., `1000`) |
| `hdfs.fileType` | `DataStream` | File format | Use `CompressedStream` for compression |
| `hdfs.writeFormat` | `Text` | Write format | Use `Writable` for binary format |
| `hdfs.batchSize` | `100` | Events per batch | Increase for performance, decrease for latency |
| `hdfs.useLocalTimeStamp` | `true` | Use local timestamp | Set to `false` for UTC |

### HDFS Sink Tinkering Ideas

1. **Change File Rolling Strategy**:
   ```properties
   # Roll every 1 minute instead of 5 minutes
   http-to-hdfs-agent.sinks.hdfs-sink.hdfs.rollInterval = 60
   
   # Roll at 1MB size
   http-to-hdfs-agent.sinks.hdfs-sink.hdfs.rollSize = 1048576
   
   # Roll after 500 events
   http-to-hdfs-agent.sinks.hdfs-sink.hdfs.rollCount = 500
   ```

2. **Add Compression**:
   ```properties
   http-to-hdfs-agent.sinks.hdfs-sink.hdfs.fileType = CompressedStream
   http-to-hdfs-agent.sinks.hdfs-sink.hdfs.codeC = gzip
   ```

3. **Change Partitioning Strategy**:
   ```properties
   # Partition by date, hour, and minute
   http-to-hdfs-agent.sinks.hdfs-sink.hdfs.path = hdfs://hadoop-master:9000/flume/events/%Y-%m-%d/%H/%M
   
   # Partition by event type
   http-to-hdfs-agent.sinks.hdfs-sink.hdfs.path = hdfs://hadoop-master:9000/flume/events/%Y-%m-%d/%H/%{event_type}
   ```

4. **Add Multiple Sinks**:
   ```properties
   # Define multiple sinks
   http-to-hdfs-agent.sinks = hdfs-sink logger-sink
   
   # Logger sink for debugging
   http-to-hdfs-agent.sinks.logger-sink.type = logger
   http-to-hdfs-agent.sinks.logger-sink.maxBytesToLog = 1000
   
   # Bind both sinks
   http-to-hdfs-agent.sinks.hdfs-sink.channel = memory-channel
   http-to-hdfs-agent.sinks.logger-sink.channel = memory-channel
   ```

## Component Binding

```properties
# Bind the source and sink to the channel
http-to-hdfs-agent.sources.http-source.channels = memory-channel
http-to-hdfs-agent.sinks.hdfs-sink.channel = memory-channel
```

**What it does**: Connects sources and sinks to channels
- Source writes to channel
- Sink reads from channel
- Multiple sources can write to same channel
- Multiple sinks can read from same channel

## Advanced Tinkering Ideas

### 1. **Add Interceptors for Data Processing**

```properties
# Add interceptors to HTTP source
http-to-hdfs-agent.sources.http-source.interceptors = timestamp search-replace
http-to-hdfs-agent.sources.http-source.interceptors.timestamp.type = timestamp
http-to-hdfs-agent.sources.http-source.interceptors.search-replace.type = search_replace
http-to-hdfs-agent.sources.http-source.interceptors.search-replace.searchPattern = password
http-to-hdfs-agent.sources.http-source.interceptors.search-replace.replaceString = **REDACTED**
```

### 2. **Add Sink Processor for Load Balancing**

```properties
# Define multiple HDFS sinks
http-to-hdfs-agent.sinks = hdfs-sink-1 hdfs-sink-2

# Sink processor for load balancing
http-to-hdfs-agent.sinkgroups = load-balancer-group
http-to-hdfs-agent.sinkgroups.load-balancer-group.sinks = hdfs-sink-1 hdfs-sink-2
http-to-hdfs-agent.sinkgroups.load-balancer-group.processor.type = load_balance
http-to-hdfs-agent.sinkgroups.load-balancer-group.processor.selector = round_robin
```

### 3. **Add Channel Selector for Data Routing**

```properties
# Define multiple channels
http-to-hdfs-agent.channels = memory-channel file-channel

# Channel selector for routing
http-to-hdfs-agent.sources.http-source.selector.type = multiplexing
http-to-hdfs-agent.sources.http-source.selector.header = event_type
http-to-hdfs-agent.sources.http-source.selector.mapping.info = memory-channel
http-to-hdfs-agent.sources.http-source.selector.mapping.error = file-channel
http-to-hdfs-agent.sources.http-source.selector.default = memory-channel
```

### 4. **Performance Tuning**

```properties
# High throughput configuration
http-to-hdfs-agent.channels.memory-channel.capacity = 10000
http-to-hdfs-agent.channels.memory-channel.transactionCapacity = 1000
http-to-hdfs-agent.sinks.hdfs-sink.hdfs.batchSize = 500
http-to-hdfs-agent.sinks.hdfs-sink.hdfs.rollInterval = 60
```

### 5. **Reliability Configuration**

```properties
# File channel for persistence
http-to-hdfs-agent.channels.memory-channel.type = file
http-to-hdfs-agent.channels.memory-channel.checkpointDir = /tmp/flume/checkpoint
http-to-hdfs-agent.channels.memory-channel.dataDirs = /tmp/flume/data
http-to-hdfs-agent.channels.memory-channel.capacity = 10000
http-to-hdfs-agent.channels.memory-channel.transactionCapacity = 1000
```

## Testing Your Changes

1. **Backup original configuration**:
   ```bash
   cp config/flume-agent.conf config/flume-agent.conf.backup
   ```

2. **Make your changes** to `config/flume-agent.conf`

3. **Restart Flume**:
   ```bash
   docker restart flume-agent
   ```

4. **Test the changes**:
   ```bash
   ./check-flume.sh
   ./test-flume.sh 5
   ./view-flume-events.sh
   ```

5. **Restore if needed**:
   ```bash
   cp config/flume-agent.conf.backup config/flume-agent.conf
   docker restart flume-agent
   ```

## Common Configuration Patterns

### **Development/Testing**
- Small capacity, frequent rolling
- Logger sink for debugging
- Memory channel for speed

### **Production**
- Large capacity, less frequent rolling
- File channel for reliability
- Compression enabled
- Multiple sinks for redundancy

### **High Throughput**
- Large batch sizes
- Multiple channels
- Load balancing sinks
- Optimized roll intervals

This configuration guide provides a foundation for understanding and experimenting with Flume's powerful data processing capabilities. 