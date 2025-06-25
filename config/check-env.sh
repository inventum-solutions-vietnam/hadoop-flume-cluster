#!/bin/bash

echo "=== Hadoop Environment Check ==="
echo ""

echo "📍 Current working directory: $(pwd)"
echo ""

echo "☕ Java Environment:"
echo "   JAVA_HOME: $JAVA_HOME"
if [ -n "$JAVA_HOME" ] && [ -d "$JAVA_HOME" ]; then
    echo "   ✅ JAVA_HOME is set and directory exists"
    echo "   Java version: $(java -version 2>&1 | head -1)"
else
    echo "   ❌ JAVA_HOME is not set or directory doesn't exist"
    echo "   Trying to detect Java..."
    DETECTED_JAVA=$(dirname $(dirname $(readlink -f $(which java))))
    echo "   Detected Java at: $DETECTED_JAVA"
    export JAVA_HOME="$DETECTED_JAVA"
    echo "   Set JAVA_HOME to: $JAVA_HOME"
fi
echo ""

echo "🐘 Hadoop Environment:"
echo "   HADOOP_HOME: $HADOOP_HOME"
echo "   HADOOP_CONF_DIR: $HADOOP_CONF_DIR"
echo "   PATH: $PATH"
if [ -n "$HADOOP_HOME" ] && [ -d "$HADOOP_HOME" ]; then
    echo "   ✅ HADOOP_HOME is set and directory exists"
    echo "   Hadoop version: $(hadoop version 2>/dev/null | head -1 || echo 'Could not get version')"
else
    echo "   ❌ HADOOP_HOME is not set or directory doesn't exist"
fi
echo ""

echo "🔧 Hadoop Configuration:"
if [ -f "$HADOOP_CONF_DIR/hadoop-env.sh" ]; then
    echo "   ✅ hadoop-env.sh exists"
    echo "   JAVA_HOME in hadoop-env.sh: $(grep 'export JAVA_HOME' $HADOOP_CONF_DIR/hadoop-env.sh | grep -v '^#' | head -1)"
else
    echo "   ❌ hadoop-env.sh not found"
fi
echo ""

echo "🚀 Ready to start Hadoop services:"
echo "   Run: ./start-hadoop.sh"
echo "" 