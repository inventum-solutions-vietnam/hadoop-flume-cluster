# syntax=docker/dockerfile:1
FROM ubuntu:24.04

LABEL org.opencontainers.image.title="Hadoop Cluster"
LABEL org.opencontainers.image.description="Modern Hadoop 3.4.1 cluster on Ubuntu 24.04 LTS"
LABEL org.opencontainers.image.version="3.4.1"
LABEL org.opencontainers.image.licenses="Apache-2.0"

# Avoid prompts from apt
ARG DEBIAN_FRONTEND=noninteractive

WORKDIR /root

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    openssh-server \
    openjdk-11-jdk \
    wget \
    curl \
    netcat-openbsd \
    sudo \
    procps \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Configure Java environment
RUN echo "Configuring Java environment..." && \
    update-alternatives --display java && \
    export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java)))) && \
    echo "JAVA_HOME=$JAVA_HOME" && \
    echo "export JAVA_HOME=$JAVA_HOME" >> /etc/environment && \
    echo "export JAVA_HOME=$JAVA_HOME" >> ~/.bashrc && \
    echo "export JAVA_HOME=$JAVA_HOME" >> ~/.profile

# Set environment variables
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
ENV HADOOP_HOME=/usr/local/hadoop
ENV HADOOP_CONF_DIR=${HADOOP_HOME}/etc/hadoop
ENV PATH=${PATH}:${HADOOP_HOME}/bin:${HADOOP_HOME}/sbin

# Add Hadoop environment to shell profiles
RUN echo "export HADOOP_HOME=/usr/local/hadoop" >> ~/.bashrc && \
    echo "export HADOOP_CONF_DIR=\$HADOOP_HOME/etc/hadoop" >> ~/.bashrc && \
    echo "export PATH=\$PATH:\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin" >> ~/.bashrc

# Install Hadoop
ARG HADOOP_VERSION=3.4.1
RUN echo "Installing Hadoop ${HADOOP_VERSION}..." && \
    wget -q "https://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz" && \
    tar -xzf "hadoop-${HADOOP_VERSION}.tar.gz" && \
    mv "hadoop-${HADOOP_VERSION}" "${HADOOP_HOME}" && \
    rm "hadoop-${HADOOP_VERSION}.tar.gz" && \
    echo "Hadoop ${HADOOP_VERSION} installed successfully"

# Install Apache Flume
ARG FLUME_VERSION=1.11.0
RUN echo "Installing Apache Flume ${FLUME_VERSION}..." && \
    wget -q "https://archive.apache.org/dist/flume/${FLUME_VERSION}/apache-flume-${FLUME_VERSION}-bin.tar.gz" && \
    tar -xzf "apache-flume-${FLUME_VERSION}-bin.tar.gz" && \
    mv "apache-flume-${FLUME_VERSION}-bin" "/usr/local/flume" && \
    rm "apache-flume-${FLUME_VERSION}-bin.tar.gz" && \
    echo "Apache Flume ${FLUME_VERSION} installed successfully"

# Set Flume environment variables
ENV FLUME_HOME=/usr/local/flume
ENV FLUME_CONF_DIR=${FLUME_HOME}/conf
ENV PATH=${PATH}:${FLUME_HOME}/bin

# Add Flume environment to shell profiles
RUN echo "export FLUME_HOME=/usr/local/flume" >> ~/.bashrc && \
    echo "export FLUME_CONF_DIR=\$FLUME_HOME/conf" >> ~/.bashrc && \
    echo "export PATH=\$PATH:\$FLUME_HOME/bin" >> ~/.bashrc

# Configure SSH for cluster communication
RUN ssh-keygen -t rsa -f ~/.ssh/id_rsa -P '' && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && \
    chmod 600 ~/.ssh/authorized_keys && \
    chmod 700 ~/.ssh

# Create Hadoop
RUN mkdir -p ~/hdfs/namenode ~/hdfs/datanode ${HADOOP_HOME}/logs

# Copy configuration files
COPY config/* /tmp/

# Install configuration files
RUN mv /tmp/ssh_config ~/.ssh/config && \
    mv /tmp/hadoop-env.sh ${HADOOP_CONF_DIR}/hadoop-env.sh && \
    mv /tmp/hdfs-site.xml ${HADOOP_CONF_DIR}/hdfs-site.xml && \
    mv /tmp/core-site.xml ${HADOOP_CONF_DIR}/core-site.xml && \
    mv /tmp/mapred-site.xml ${HADOOP_CONF_DIR}/mapred-site.xml && \
    mv /tmp/yarn-site.xml ${HADOOP_CONF_DIR}/yarn-site.xml && \
    mv /tmp/workers ${HADOOP_CONF_DIR}/workers && \
    mv /tmp/start-hadoop.sh ~/start-hadoop.sh && \
    mv /tmp/check-cluster-health.sh ~/check-cluster-health.sh && \
    mv /tmp/check-env.sh ~/check-env.sh && \
    mv /tmp/flume-agent.conf ${FLUME_CONF_DIR}/flume-agent.conf && \
    mv /tmp/log4j2.xml ${FLUME_CONF_DIR}/log4j2.xml && \
    mv /tmp/start-flume.sh ~/start-flume.sh && \
    rm -f /tmp/slaves

# Update Hadoop configuration with detected Java path
RUN DETECTED_JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java)))) && \
    sed -i "s|# export JAVA_HOME=.*|export JAVA_HOME=${DETECTED_JAVA_HOME}|" ${HADOOP_CONF_DIR}/hadoop-env.sh && \
    echo "Updated hadoop-env.sh with JAVA_HOME: ${DETECTED_JAVA_HOME}"

# Make scripts executable
RUN chmod +x ~/start-hadoop.sh ~/check-cluster-health.sh ~/check-env.sh ~/start-flume.sh && \
    chmod +x ${HADOOP_HOME}/sbin/*.sh

# Initialize HDFS
RUN . /etc/environment && \
    export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java)))) && \
    echo "Initializing HDFS with JAVA_HOME: $JAVA_HOME" && \
    ${HADOOP_HOME}/bin/hdfs namenode -format -force

# Expose Hadoop ports
EXPOSE 9000 9870 8088 8042 8888

# Health check
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD pgrep sshd > /dev/null || exit 1

# Create entrypoint script
RUN echo '#!/bin/bash' > /entrypoint.sh && \
    echo 'set -e' >> /entrypoint.sh && \
    echo '' >> /entrypoint.sh && \
    echo '# Initialize environment' >> /entrypoint.sh && \
    echo '. /etc/environment' >> /entrypoint.sh && \
    echo 'export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))' >> /entrypoint.sh && \
    echo 'export HADOOP_HOME=/usr/local/hadoop' >> /entrypoint.sh && \
    echo 'export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop' >> /entrypoint.sh && \
    echo 'export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin' >> /entrypoint.sh && \
    echo '' >> /entrypoint.sh && \
    echo '# Start SSH daemon' >> /entrypoint.sh && \
    echo 'service ssh start' >> /entrypoint.sh && \
    echo '' >> /entrypoint.sh && \
    echo '# Keep container running or execute commands' >> /entrypoint.sh && \
    echo 'if [ "$#" -eq 0 ]; then' >> /entrypoint.sh && \
    echo '    exec tail -f /dev/null' >> /entrypoint.sh && \
    echo 'else' >> /entrypoint.sh && \
    echo '    exec "$@"' >> /entrypoint.sh && \
    echo 'fi' >> /entrypoint.sh && \
    chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

