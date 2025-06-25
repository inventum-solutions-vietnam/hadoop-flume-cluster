#!/bin/bash

set -e

echo "Starting Flume Agent..."

# Set environment variables
export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))
export HADOOP_HOME=/usr/local/hadoop
export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
export FLUME_HOME=/usr/local/flume
export FLUME_CONF_DIR=$FLUME_HOME/conf
export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$FLUME_HOME/bin

# Wait for HDFS to be ready
echo "Waiting for HDFS to be ready..."
until $HADOOP_HOME/bin/hdfs dfsadmin -report -namenode hadoop-master:9000 > /dev/null 2>&1; do
    echo "HDFS not ready yet, waiting..."
    sleep 5
done

echo "HDFS is ready!"

# Create flume directory in HDFS if it doesn't exist
echo "Creating flume directory in HDFS..."
$HADOOP_HOME/bin/hdfs dfs -mkdir -p /flume/events

# Start Flume agent
echo "Starting Flume agent with configuration: $FLUME_CONF_DIR/flume-agent.conf"
$FLUME_HOME/bin/flume-ng agent \
    --name http-to-hdfs-agent \
    --conf $FLUME_CONF_DIR \
    --conf-file $FLUME_CONF_DIR/flume-agent.conf \
    -Dflume.root.logger=INFO,console \
    -Dlog4j.configurationFile=$FLUME_CONF_DIR/log4j2.xml \
    -Xmx512m 