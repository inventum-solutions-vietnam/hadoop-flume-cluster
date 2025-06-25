#!/bin/bash

# Hadoop Cluster Docker Image Builder
# Builds a modern Hadoop cluster image with best practices

set -e

echo ""
echo "🔨 Building Hadoop Docker Image"
echo "================================="

# Enable BuildKit for enhanced features and performance
export DOCKER_BUILDKIT=1

# Build configuration
IMAGE_NAME="hadoop-cluster"
HADOOP_VERSION="3.4.1"

echo "📦 Configuration:"
echo "   Image Name: ${IMAGE_NAME}"
echo "   Hadoop Version: ${HADOOP_VERSION}"
echo "   Base OS: Ubuntu 24.04 LTS"
echo "   Java Version: OpenJDK 11"
echo ""

echo "🏗️  Building image..."

# Build the Docker image
docker build \
    --tag "${IMAGE_NAME}:${HADOOP_VERSION}" \
    --tag "${IMAGE_NAME}:latest" \
    --build-arg HADOOP_VERSION="${HADOOP_VERSION}" \
    --progress=plain \
    .

BUILD_STATUS=$?

echo ""
if [ $BUILD_STATUS -eq 0 ]; then
    echo "✅ Build completed successfully!"
    echo ""
    echo "📊 Image Information:"
    docker images "${IMAGE_NAME}:latest" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
    echo ""
    echo "🚀 Next Steps:"
    echo "   Start cluster: ./start-cluster.sh"
    echo "   Scale cluster: ./scale-cluster.sh <number_of_workers>"
    echo ""
else
    echo "❌ Build failed with exit code: $BUILD_STATUS"
    exit $BUILD_STATUS
fi