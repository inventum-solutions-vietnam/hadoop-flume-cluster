#!/bin/bash

# Hadoop Cluster Scaling Script
# Dynamically scales the number of worker nodes in the cluster

set -e

# Configuration
N=${1:-2}

# Usage information
show_usage() {
    echo "Usage: $0 <number_of_workers>"
    echo ""
    echo "Examples:"
    echo "  $0 2    # Scale to 2 worker nodes"
    echo "  $0 5    # Scale to 5 worker nodes"
    echo ""
    echo "Note: Docker Compose configuration supports up to 2 workers by default."
    echo "      For more workers, manually edit docker-compose.yml"
}

# Validate input
if [ $# -eq 0 ]; then
    echo "❌ Error: Number of workers not specified"
    echo ""
    show_usage
    exit 1
fi

if [ "$N" -lt 1 ]; then
    echo "❌ Error: Number of workers must be at least 1"
    exit 1
fi

echo ""
echo "⚖️  Hadoop Cluster Scaling"
echo "=========================="
echo "   Target Workers: ${N}"
echo ""

# Detect Docker Compose command
if docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
elif command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
else
    echo "❌ Docker Compose not found!"
    exit 1
fi

# Update workers configuration
echo "📝 Updating cluster configuration..."
cat > config/workers << EOF
# Hadoop Worker Nodes Configuration
# List the hostnames of all worker nodes in the cluster
# One hostname per line

EOF

for ((i=1; i<=N; i++)); do
    echo "hadoop-slave${i}" >> config/workers
done

echo "✅ Updated workers configuration for ${N} nodes"

# Check if cluster is running
if $COMPOSE_CMD ps | grep -q "hadoop-master"; then
    echo ""
    echo "🔄 Cluster is running - applying configuration changes..."
    
    # Restart master to pick up new configuration
    echo "   Restarting master node..."
    $COMPOSE_CMD restart hadoop-master
    
    # Handle worker scaling
    echo "   Scaling worker nodes..."
    if [ "$N" -eq 1 ]; then
        $COMPOSE_CMD up -d hadoop-slave1
        $COMPOSE_CMD stop hadoop-slave2 2>/dev/null || true
    elif [ "$N" -eq 2 ]; then
        $COMPOSE_CMD up -d hadoop-slave1 hadoop-slave2
    else
        echo ""
        echo "⚠️  Advanced Scaling Required"
        echo "   Current Docker Compose configuration supports up to 2 workers."
        echo "   For ${N} workers, please:"
        echo "   1. Edit docker-compose.yml to add hadoop-slave3, hadoop-slave4, etc."
        echo "   2. Run: $COMPOSE_CMD up -d"
        echo ""
        echo "   Example service definition:"
        echo "   hadoop-slave3:"
        echo "     build: ."
        echo "     container_name: hadoop-slave3"
        echo "     hostname: hadoop-slave3"
        echo "     # ... (copy configuration from hadoop-slave1)"
        echo ""
    fi
else
    echo ""
    echo "🚀 Starting new cluster with ${N} workers..."
    $COMPOSE_CMD up -d
fi

echo ""
echo "✅ Cluster scaling completed!"
echo ""
echo "🔍 Current Status:"
$COMPOSE_CMD ps

echo ""
echo "🌐 Web Interfaces:"
echo "   NameNode:        http://localhost:9870"
echo "   ResourceManager: http://localhost:8088"
echo ""
echo "💡 Next Steps:"
echo "   1. Access master: docker exec -it hadoop-master bash"
echo "   2. Restart Hadoop services to apply worker changes"
echo "   3. Verify nodes: hadoop dfsadmin -report"
echo "" 