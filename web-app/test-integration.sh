#!/bin/bash

# Test script for Flume Web App Integration

echo "🧪 Testing Flume Web App Integration..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    if [ "$status" = "success" ]; then
        echo -e "${GREEN}✅ $message${NC}"
    elif [ "$status" = "error" ]; then
        echo -e "${RED}❌ $message${NC}"
    elif [ "$status" = "warning" ]; then
        echo -e "${YELLOW}⚠️  $message${NC}"
    else
        echo "ℹ️  $message"
    fi
}

# Check if web app is running
echo "🔍 Checking if web app is running..."
if curl -s http://localhost:3000 > /dev/null 2>&1; then
    print_status "success" "Web app is running on port 3000"
else
    print_status "error" "Web app is not running on port 3000"
    echo "   Start the web app with: cd web-app && ./start.sh"
    exit 1
fi

# Check if Flume agent is running
echo "🔍 Checking if Flume agent is running..."
if curl -s http://localhost:44444 > /dev/null 2>&1; then
    print_status "success" "Flume agent is running on port 44444"
else
    print_status "warning" "Flume agent is not running on port 44444"
    echo "   Start the cluster with: ./start-cluster.sh"
fi

# Test health endpoint
echo "🔍 Testing health endpoint..."
HEALTH_RESPONSE=$(curl -s http://localhost:3000/api/health)
if [ $? -eq 0 ]; then
    print_status "success" "Health endpoint is working"
    echo "   Response: $HEALTH_RESPONSE"
else
    print_status "error" "Health endpoint failed"
fi

# Test form submission
echo "🔍 Testing form submission..."
FORM_RESPONSE=$(curl -s -X POST http://localhost:3000/api/submit \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "action": "test_submission",
    "message": "Integration test",
    "priority": "medium"
  }')

if [ $? -eq 0 ]; then
    print_status "success" "Form submission endpoint is working"
    echo "   Response: $FORM_RESPONSE"
else
    print_status "error" "Form submission endpoint failed"
fi

# Test backend log
echo "🔍 Testing backend log endpoint..."
LOG_RESPONSE=$(curl -s -X POST http://localhost:3000/api/log \
  -H "Content-Type: application/json" \
  -d '{
    "level": "INFO",
    "message": "Integration test log",
    "component": "test-script",
    "details": {"test": true}
  }')

if [ $? -eq 0 ]; then
    print_status "success" "Backend log endpoint is working"
    echo "   Response: $LOG_RESPONSE"
else
    print_status "error" "Backend log endpoint failed"
fi

# Test test-log endpoint
echo "🔍 Testing test-log endpoint..."
TEST_LOG_RESPONSE=$(curl -s -X POST http://localhost:3000/api/test-log)
if [ $? -eq 0 ]; then
    print_status "success" "Test log endpoint is working"
    echo "   Response: $TEST_LOG_RESPONSE"
else
    print_status "error" "Test log endpoint failed"
fi

echo ""
echo "🎉 Integration test completed!"
echo ""
echo "📊 Next steps:"
echo "   1. Open http://localhost:3000 in your browser"
echo "   2. Fill out the form and submit"
echo "   3. Check Flume logs: docker logs flume-agent"
echo "   4. Check HDFS for stored events" 