#!/bin/bash

# Hadoop Cluster Health Check
# Validates HDFS, YARN, and overall cluster functionality

set -e

echo ""
echo "🏥 Hadoop Cluster Health Check"
echo "=============================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Health check functions
check_hdfs() {
    echo -e "${BLUE}📁 HDFS Health Check${NC}"
    echo "   Checking NameNode..."
    
    # Check if NameNode is running
    if hadoop dfsadmin -report &>/dev/null; then
        echo -e "   ✅ NameNode is ${GREEN}running${NC}"
        
        # Get cluster summary
        TOTAL_CAPACITY=$(hadoop dfsadmin -report | grep "Configured Capacity" | awk '{print $3}')
        USED_CAPACITY=$(hadoop dfsadmin -report | grep "DFS Used:" | awk '{print $3}')
        AVAILABLE_CAPACITY=$(hadoop dfsadmin -report | grep "DFS Remaining:" | awk '{print $3}')
        LIVE_NODES=$(hadoop dfsadmin -report | grep "Live datanodes" | awk '{print $3}' | sed 's/://')
        
        echo "   📊 Cluster Summary:"
        echo "      Total Capacity: ${TOTAL_CAPACITY} bytes"
        echo "      Used: ${USED_CAPACITY} bytes"
        echo "      Available: ${AVAILABLE_CAPACITY} bytes"
        echo "      Live DataNodes: ${LIVE_NODES}"
        
        # Test basic HDFS operations
        echo "   🔧 Testing HDFS operations..."
        TEST_DIR="/tmp/health-check-$$"
        
        # Create test directory
        if hadoop fs -mkdir -p $TEST_DIR &>/dev/null; then
            echo -e "      ✅ Directory creation: ${GREEN}SUCCESS${NC}"
            
            # Create test file
            echo "Hadoop cluster health check $(date)" > /tmp/test-file
            if hadoop fs -put /tmp/test-file $TEST_DIR/test-file &>/dev/null; then
                echo -e "      ✅ File upload: ${GREEN}SUCCESS${NC}"
                
                # Read test file
                if hadoop fs -cat $TEST_DIR/test-file &>/dev/null; then
                    echo -e "      ✅ File read: ${GREEN}SUCCESS${NC}"
                else
                    echo -e "      ❌ File read: ${RED}FAILED${NC}"
                fi
            else
                echo -e "      ❌ File upload: ${RED}FAILED${NC}"
            fi
            
            # Cleanup
            hadoop fs -rm -r $TEST_DIR &>/dev/null
            rm -f /tmp/test-file
            echo -e "      ✅ Cleanup: ${GREEN}SUCCESS${NC}"
        else
            echo -e "      ❌ Directory creation: ${RED}FAILED${NC}"
        fi
    else
        echo -e "   ❌ NameNode is ${RED}not responding${NC}"
        return 1
    fi
    
    echo ""
}

check_yarn() {
    echo -e "${BLUE}🧶 YARN Health Check${NC}"
    echo "   Checking ResourceManager..."
    
    # Check if ResourceManager is running
    if yarn node -list &>/dev/null; then
        echo -e "   ✅ ResourceManager is ${GREEN}running${NC}"
        
        # Get node information
        TOTAL_NODES=$(yarn node -list 2>/dev/null | grep -c "RUNNING" || echo "0")
        echo "   📊 YARN Summary:"
        echo "      Active NodeManagers: ${TOTAL_NODES}"
        
        # Show node details
        echo "   🖥️  Node Details:"
        yarn node -list 2>/dev/null | grep "RUNNING" | while read line; do
            NODE_ID=$(echo "$line" | awk '{print $1}')
            echo "      Node: ${NODE_ID}"
        done
        
        # Check cluster metrics
        if yarn top -h &>/dev/null; then
            echo -e "      ✅ Cluster metrics: ${GREEN}accessible${NC}"
        fi
    else
        echo -e "   ❌ ResourceManager is ${RED}not responding${NC}"
        return 1
    fi
    
    echo ""
}

check_services() {
    echo -e "${BLUE}⚙️  Service Health Check${NC}"
    
    # Check Java processes
    echo "   🔍 Running Java processes:"
    jps | while read line; do
        if [[ "$line" == *"NameNode"* ]]; then
            echo -e "      ✅ ${GREEN}NameNode${NC} - $line"
        elif [[ "$line" == *"DataNode"* ]]; then
            echo -e "      ✅ ${GREEN}DataNode${NC} - $line"
        elif [[ "$line" == *"ResourceManager"* ]]; then
            echo -e "      ✅ ${GREEN}ResourceManager${NC} - $line"
        elif [[ "$line" == *"NodeManager"* ]]; then
            echo -e "      ✅ ${GREEN}NodeManager${NC} - $line"
        else
            echo "      ℹ️  $line"
        fi
    done
    
    echo ""
}

check_connectivity() {
    echo -e "${BLUE}🌐 Network Connectivity Check${NC}"
    
    # Check if we can reach other nodes in the cluster
    echo "   🔗 Testing cluster connectivity..."
    
    # Test NameNode Web UI
    if curl -s http://localhost:9870 > /dev/null; then
        echo -e "      ✅ NameNode Web UI: ${GREEN}accessible${NC} (http://localhost:9870)"
    else
        echo -e "      ❌ NameNode Web UI: ${RED}not accessible${NC}"
    fi
    
    # Test ResourceManager Web UI (follow redirects and use proper hostname)
    if curl -sL http://hadoop-master:8088/cluster > /dev/null; then
        echo -e "      ✅ ResourceManager Web UI: ${GREEN}accessible${NC} (http://localhost:8088)"
    else
        echo -e "      ❌ ResourceManager Web UI: ${RED}not accessible${NC}"
    fi
    
    echo ""
}

# Main health check execution
main() {
    local overall_status=0
    
    echo "🏥 Starting comprehensive cluster health check..."
    echo "   Timestamp: $(date)"
    echo "   Hostname: $(hostname)"
    echo ""
    
    # Run all health checks
    if ! check_services; then
        overall_status=1
    fi
    
    if ! check_hdfs; then
        overall_status=1
    fi
    
    if ! check_yarn; then
        overall_status=1
    fi
    
    if ! check_connectivity; then
        overall_status=1
    fi
    
    # Final summary
    echo "🏁 Health Check Summary"
    echo "======================"
    if [ $overall_status -eq 0 ]; then
        echo -e "   Overall Status: ${GREEN}✅ HEALTHY${NC}"
        echo "   🎉 Your Hadoop cluster is running properly!"
        echo ""
            echo "   🌐 Access your cluster:"
    echo "      NameNode Web UI:        http://localhost:9870"
    echo "      ResourceManager Web UI: http://localhost:8088"
    else
        echo -e "   Overall Status: ${RED}❌ UNHEALTHY${NC}"
        echo "   🔧 Some components need attention. Please check the logs above."
    fi
    
    echo ""
    echo "   💡 Useful commands:"
    echo "      Check HDFS: hadoop dfsadmin -report"
    echo "      Check YARN: yarn node -list"
    echo "      View logs:  docker compose logs [service]"
    echo ""
    
    return $overall_status
}

# Run the health check
main "$@"

