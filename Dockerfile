FROM ubuntu:22.04

ENV HADOOP_VERSION=3.3.6
ENV SPARK_VERSION=3.5.1

ENV HADOOP_HOME=/opt/hadoop
ENV SPARK_HOME=/opt/spark
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
ENV HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop
ENV PATH="$JAVA_HOME/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$SPARK_HOME/bin:$PATH"

ENV KAGGLE_CONFIG_DIR=/app/src/kaggle

RUN apt-get update && apt-get install -y \
    openjdk-11-jdk curl wget python3 python3-pip nano sudo openssh-server rsync unzip && \
    rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash hadoop && echo "hadoop ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

RUN curl -sSL https://downloads.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz -o hadoop.tar.gz && \
    tar -xzf hadoop.tar.gz -C /opt && \
    mv /opt/hadoop-${HADOOP_VERSION} ${HADOOP_HOME} && \
    rm hadoop.tar.gz && \
    sed -i '/^export JAVA_HOME/d' $HADOOP_HOME/etc/hadoop/hadoop-env.sh && \
    echo "export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh

RUN curl -sSL https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop3.tgz -o spark.tgz && \
    tar -xzf spark.tgz -C /opt && \
    mv /opt/spark-${SPARK_VERSION}-bin-hadoop3 ${SPARK_HOME} && \
    rm spark.tgz

RUN mkdir -p $HADOOP_HOME/data/namenode $HADOOP_HOME/data/datanode && \
    chown -R hadoop:hadoop $HADOOP_HOME

RUN pip3 install --upgrade pip && \
    pip3 install --no-cache-dir jupyterlab pyspark pandas kagglehub kaggle

RUN mkdir -p /home/hadoop/.ssh && \
    ssh-keygen -t rsa -P "" -f /home/hadoop/.ssh/id_rsa && \
    cat /home/hadoop/.ssh/id_rsa.pub >> /home/hadoop/.ssh/authorized_keys && \
    chmod 600 /home/hadoop/.ssh/authorized_keys && \
    chown -R hadoop:hadoop /home/hadoop/.ssh && \
    mkdir -p /var/run/sshd

WORKDIR /app

RUN mkdir -p /app/notebooks /app/src /app/data
COPY src/ /app/src/
COPY data/ /app/data/

RUN chmod 600 /app/src/kaggle/kaggle.json && \
    chown -R hadoop:hadoop /app/src/kaggle

RUN chown -R hadoop:hadoop $HADOOP_HOME $SPARK_HOME /app

COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

EXPOSE 8888 9870 8088 7077 4040

USER hadoop
CMD ["/app/start.sh"]
