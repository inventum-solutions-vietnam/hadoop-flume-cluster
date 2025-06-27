# Modern Hadoop Cluster with Docker

A modernized Docker-based Hadoop cluster setup with the latest versions and best practices for production use.

![Hadoop Version](https://img.shields.io/badge/Hadoop-3.4.1-green)
![Java Version](https://img.shields.io/badge/Java-11-blue)
![Ubuntu Version](https://img.shields.io/badge/Ubuntu-24.04-orange)
![Docker](https://img.shields.io/badge/Docker-Compose-blue)
![License](https://img.shields.io/badge/License-Apache%202.0-lightgrey)

## 🚀 Features

This is a completely modernized Hadoop cluster Docker setup featuring:

- **Hadoop 3.4.1** - Latest stable release (October 2024)
- **Java 11** - Enhanced performance and security
- **Ubuntu 24.04 LTS** - Long-term support until 2029
- **Docker best practices** - Security, optimization, and maintainability
- **Docker Compose orchestration** - Easy cluster management
- **Modern configuration** - Optimized for containerized environments
- **Production-ready** - Health checks, logging, and monitoring support
- **Apache Flume Integration** - HTTP source to HDFS sink for event aggregation
- **Web Application** - Hono.js web app for user interaction logging

## 📊 Data Ingestion with Apache Flume

The cluster includes Apache Flume for real-time data ingestion:

- **HTTP Source** - Receive events via HTTP POST on port 44444
- **Memory Channel** - Buffer events in memory for high throughput
- **HDFS Sink** - Write events to HDFS with time-based partitioning
- **JSON Support** - Native JSON event handling
- **Automatic Partitioning** - Events organized by date/hour in HDFS

For detailed Flume usage, see [FLUME_README.md](FLUME_README.md).

## 🌐 Web Application for User Interaction Logging

A modern Hono.js web application is included for capturing user interactions and backend logs:

- **User Interaction Form** - Collect user data and interactions via web interface
- **Backend Logging API** - Send application logs to Flume agent
- **Health Monitoring** - Real-time system and Flume agent status
- **Modern UI** - Beautiful, responsive interface with real-time feedback
- **RESTful API** - Easy integration with other applications

### Quick Start for Web App

```bash
# Navigate to web app directory
cd web-app

# Install dependencies and start
./start.sh

# Or manually
npm install
npm run dev
```

The web app will be available at `http://localhost:3000`

### Web App Features

- **Form Submission** - Capture user interactions with rich metadata
- **Backend Logging** - Send structured logs to Flume agent
- **Health Checks** - Monitor system and Flume agent connectivity
- **Test Integration** - Verify Flume agent connectivity
- **Session Tracking** - Automatic session ID generation and tracking

### API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | Web interface |
| `/api/submit` | POST | Submit user interaction form |
| `/api/log` | POST | Send backend log message |
| `/api/test-log` | POST | Send test log to Flume |
| `/api/health` | GET | Check system health |

For detailed web app documentation, see [web-app/README.md](web-app/README.md).

## 📋 Prerequisites

- **Docker Engine** 20.10+ 
- **Docker Compose** 2.0+ (or docker-compose 1.29+)
- **System Resources**: 4GB RAM, 10GB disk space
- **Operating System**: Linux, macOS, or Windows with WSL2

## 🏗️ Quick Start

### 1. Clone and Build

```bash
git clone <repository-url>
cd hadoop-cluster-docker

# Build the cluster image
./build-image.sh
```

### 2. Start the Cluster

```bash
# Start with default configuration (3 nodes)
./start-cluster.sh

# Or use Docker Compose directly
docker compose up -d
```

### 3. Access Web Interfaces

| Service | URL | Description |
|---------|-----|-------------|
| NameNode | http://localhost:9870 | HDFS Management |
| ResourceManager | http://localhost:8088 | YARN Resource Management |
| Flume Agent | http://localhost:44444 | HTTP Event Ingestion |

| NodeManager 1 | http://localhost:8042 | Worker Node 1 |
| NodeManager 2 | http://localhost:8043 | Worker Node 2 |

### 4. Start Hadoop Services

```bash
# Access the master node
docker exec -it hadoop-master bash

# Check environment setup
./check-env.sh

# Start Hadoop services
./start-hadoop.sh

# Validate cluster health
./check-cluster-health.sh
```

### 5. Test Flume Data Ingestion (Optional)

```bash
# Send test events to Flume
./test-flume.sh 10

# Check events in HDFS
docker exec -it hadoop-master hdfs dfs -ls /flume/events/
```

## 🔧 Advanced Configuration

### Scaling the Cluster

```bash
# Scale to different number of workers
./scale-cluster.sh 3   # 3 worker nodes
./scale-cluster.sh 5   # 5 worker nodes (requires manual docker-compose.yml edit)
```

### Custom Configuration

Configuration files are located in `config/`:

- `core-site.xml` - Core Hadoop settings
- `hdfs-site.xml` - HDFS configuration  
- `yarn-site.xml` - YARN resource management
- `mapred-site.xml` - MapReduce framework settings
- `hadoop-env.sh` - Environment variables
- `workers` - List of worker node hostnames

### Resource Allocation

Default resource allocation:

| Component | Memory | CPU Cores | Heap Size |
|-----------|--------|-----------|-----------|
| NameNode | - | - | 1GB |
| DataNode | - | - | 1GB |
| ResourceManager | - | - | 1GB |
| NodeManager | 2GB | 2 | 1GB |
| Map Tasks | 1GB | - | 768MB |
| Reduce Tasks | 1GB | - | 768MB |

Adjust these values in the respective XML configuration files.

### Data Persistence

Data is persisted using Docker volumes:

- `hadoop-master-data` - NameNode metadata and logs
- `hadoop-slave1-data` - DataNode 1 data
- `hadoop-slave2-data` - DataNode 2 data  
- `hadoop-logs` - Cluster logs

## 🛡️ Security Features

- **Minimal attack surface** - Ubuntu 24.04 LTS with essential packages only
- **User permissions** - Proper file and directory permissions
- **SSH key authentication** - Passwordless cluster communication
- **Health monitoring** - Container health checks
- **Resource isolation** - Docker networking and volumes

## 📊 Monitoring and Management

### Cluster Health

```bash
# Check container status
docker compose ps

# View logs
docker compose logs hadoop-master
docker compose logs hadoop-slave1

# Monitor resource usage
docker stats

# Access container shell
docker exec -it hadoop-master bash
```

### Common Operations

```bash
# Stop the cluster
docker compose down

# Stop and remove all data (⚠️ destructive)
docker compose down -v

# Restart with latest changes
docker compose up -d --build

# View cluster configuration
docker exec -it hadoop-master hadoop dfsadmin -report
```

## 🐛 Troubleshooting

### Common Issues

**1. Container startup failures**
- Check available system resources (memory/disk)
- Review logs: `docker compose logs [service-name]`
- Verify port availability

**2. Hadoop services won't start**
- Verify Java environment: `./check-env.sh`
- Check configuration files in `/usr/local/hadoop/etc/hadoop/`
- Review Hadoop logs in `/usr/local/hadoop/logs/`

**3. Web UI not accessible**
- Ensure containers are healthy: `docker compose ps`
- Check port bindings: `docker port hadoop-master`
- Verify firewall settings

**4. Out of memory errors**
- Increase Docker memory limits
- Reduce heap sizes in configuration files
- Scale down concurrent tasks

### Getting Help

```bash
# Environment diagnostic
docker exec -it hadoop-master ./check-env.sh

# Hadoop cluster report
docker exec -it hadoop-master hadoop dfsadmin -report

# Java processes
docker exec -it hadoop-master jps
```

## 🔄 Migration Guide

### From Hadoop 2.x

1. **Backup existing data** - Export HDFS data before migration
2. **Review configurations** - Update XML files for Hadoop 3.x compatibility
3. **Test applications** - Validate MapReduce jobs and custom applications
4. **Update client libraries** - Ensure client applications use Hadoop 3.x APIs

### From Legacy Docker Setups

1. **Stop old containers** - `docker stop $(docker ps -aq)`
2. **Remove old images** - `docker rmi $(docker images -q)`
3. **Clean volumes** - `docker volume prune` (⚠️ removes all data)
4. **Deploy new setup** - Follow quick start guide

## 📚 Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   hadoop-master │    │  hadoop-slave1  │    │  hadoop-slave2  │
│                 │    │                 │    │                 │
│ NameNode        │◄──►│ DataNode        │    │ DataNode        │
│ ResourceManager │    │ NodeManager     │    │ NodeManager     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
        │                       │                       │
        └───────────────────────┼───────────────────────┘
                                │
                      Docker Network
                    (172.21.0.0/16)
```

## 🤝 Contributing

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/new-feature`
3. **Make your changes** and test thoroughly
4. **Commit changes**: `git commit -am 'Add new feature'`
5. **Push to branch**: `git push origin feature/new-feature`
6. **Submit a Pull Request**

### Development Guidelines

- Follow Docker best practices
- Update documentation for configuration changes
- Test on multiple platforms when possible
- Maintain backward compatibility when feasible

## 📝 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Apache Hadoop community for excellent documentation
- Docker community for containerization best practices
- Ubuntu team for providing reliable base images
- Contributors and users of this project

---

**Need help?** Check the troubleshooting section or open an issue with detailed information about your environment and the problem you're experiencing.

