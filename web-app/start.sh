#!/bin/bash

# Flume Web App Startup Script

echo "🚀 Starting Flume Web App..."

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js 18+ first."
    exit 1
fi

# Check Node.js version
NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
    echo "❌ Node.js version 18+ is required. Current version: $(node -v)"
    exit 1
fi

echo "✅ Node.js version: $(node -v)"

# Install dependencies if node_modules doesn't exist
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
fi

# Check if Flume agent is accessible
echo "🔍 Checking Flume agent connectivity..."
if curl -s http://localhost:44444 > /dev/null 2>&1; then
    echo "✅ Flume agent is accessible at localhost:44444"
else
    echo "⚠️  Warning: Flume agent not accessible at localhost:44444"
    echo "   Make sure your Hadoop cluster is running with: ./start-cluster.sh"
fi

# Set default environment variables if not set
export FLUME_HOST=${FLUME_HOST:-localhost}
export FLUME_PORT=${FLUME_PORT:-44444}
export PORT=${PORT:-3000}

echo "📊 Configuration:"
echo "   - Flume Agent: $FLUME_HOST:$FLUME_PORT"
echo "   - Web App Port: $PORT"
echo "   - Web App URL: http://localhost:$PORT"

# Start the application
echo "🌐 Starting web application..."
npm run dev 