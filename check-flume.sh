#!/bin/bash

echo "=== Flume Agent Status Check ==="

# Check if Flume container is running
echo "1. Checking Flume container status..."
if docker ps | grep -q flume-agent; then
    echo "✅ Flume container is running"
else
    echo "❌ Flume container is not running"
    exit 1
fi

# Check Flume HTTP endpoint
echo "2. Checking Flume HTTP endpoint..."
if curl -s -f http://localhost:44444 > /dev/null 2>&1; then
    echo "✅ Flume HTTP endpoint is accessible"
else
    echo "❌ Flume HTTP endpoint is not accessible"
fi

# Check Flume logs
echo "3. Recent Flume logs:"
docker logs --tail 10 flume-agent

# Check HDFS connectivity from Flume
echo "4. Checking HDFS connectivity from Flume container..."
if docker exec flume-agent hdfs dfsadmin -report -namenode hadoop-master:9000 > /dev/null 2>&1; then
    echo "✅ Flume can connect to HDFS"
else
    echo "❌ Flume cannot connect to HDFS"
fi

# Check if flume directory exists in HDFS
echo "5. Checking Flume directory in HDFS..."
if docker exec hadoop-master hdfs dfs -test -d /flume/events 2>/dev/null; then
    echo "✅ Flume directory exists in HDFS"
    echo "   Directory contents:"
    docker exec hadoop-master hdfs dfs -ls /flume/events/ 2>/dev/null || echo "   (empty)"
else
    echo "❌ Flume directory does not exist in HDFS"
fi

echo "=== Status Check Complete ===" 