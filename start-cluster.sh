#!/bin/bash

# Hadoop Cluster Startup Script
# Starts a multi-node Hadoop cluster using Docker Compose

set -e

# Configuration
DEFAULT_NODES=3
N=${1:-$DEFAULT_NODES}

echo ""
echo "🚀 Hadoop Cluster Startup"
echo "========================="
echo "   Target Nodes: ${N} (1 master + $((N-1)) workers)"
echo "   Orchestration: Docker Compose"
echo ""

# Detect Docker Compose command
if docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
elif command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
else
    echo "❌ Docker Compose not found!"
    echo "   Please install Docker Compose to continue."
    echo "   Visit: https://docs.docker.com/compose/install/"
    exit 1
fi

echo "🔧 Using: ${COMPOSE_CMD}"
echo ""

# Start the cluster
echo "📦 Starting containers..."
$COMPOSE_CMD up -d --build

STARTUP_STATUS=$?

if [ $STARTUP_STATUS -ne 0 ]; then
    echo "❌ Failed to start containers!"
    exit $STARTUP_STATUS
fi

echo ""
echo "⏳ Waiting for cluster initialization..."

# Wait for master node to be ready
TIMEOUT=60
ELAPSED=0
while ! docker exec hadoop-master pgrep sshd &> /dev/null; do
    if [ $ELAPSED -ge $TIMEOUT ]; then
        echo "⚠️  Timeout waiting for cluster to start"
        echo "   Check logs: $COMPOSE_CMD logs"
        exit 1
    fi
    echo "   Initializing... (${ELAPSED}s/${TIMEOUT}s)"
    sleep 5
    ELAPSED=$((ELAPSED + 5))
done

echo ""
echo "✅ Hadoop Cluster Started Successfully!"
echo ""
echo "🌐 Web Interfaces:"
echo "   NameNode Web UI:        http://localhost:9870"
echo "   ResourceManager Web UI: http://localhost:8088"

echo "   NodeManager 1:          http://localhost:8042"
echo "   NodeManager 2:          http://localhost:8043"
echo ""
echo "🔧 Cluster Management:"
echo "   Access master:    docker exec -it hadoop-master bash"
echo "   Check status:     $COMPOSE_CMD ps"
echo "   View logs:        $COMPOSE_CMD logs [service]"
echo "   Stop cluster:     $COMPOSE_CMD down"
echo ""
echo "📋 Next Steps:"
echo "   1. Access master node: docker exec -it hadoop-master bash"
echo "   2. Check environment:  ./check-env.sh"
echo "   3. Start Hadoop:       ./start-hadoop.sh"
echo "   5. Validate cluster:   ./check-cluster-health.sh"
echo "" 