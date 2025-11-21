FROM eclipse-temurin:11-jdk-focal

ENV HADOOP_VERSION=3.3.6
ENV SPARK_VERSION=3.5.1
ENV HADOOP_HOME=/opt/hadoop
ENV SPARK_HOME=/opt/spark
ENV PATH="$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$SPARK_HOME/bin:$PATH"

RUN apt-get update && apt-get install -y \
    wget curl python3 python3-pip nano sudo openssh-server rsync && \
    rm -rf /var/lib/apt/lists/*

RUN wget https://downloads.apache.org/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz && \
    tar -xzf hadoop-$HADOOP_VERSION.tar.gz && \
    mv hadoop-$HADOOP_VERSION $HADOOP_HOME && \
    rm hadoop-$HADOOP_VERSION.tar.gz

RUN wget https://archive.apache.org/dist/spark/spark-$SPARK_VERSION/spark-$SPARK_VERSION-bin-hadoop3.tgz && \
    tar -xzf spark-$SPARK_VERSION-bin-hadoop3.tgz && \
    mv spark-$SPARK_VERSION-bin-hadoop3 $SPARK_HOME && \
    rm spark-$SPARK_VERSION-bin-hadoop3.tgz

RUN mkdir -p /opt/hadoop/data/namenode && \
    mkdir -p /opt/hadoop/data/datanode

RUN pip3 install jupyterlab pyspark pandas kagglehub

WORKDIR /app
RUN mkdir -p /app/notebooks

COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

EXPOSE 8888 9870 8088 7077 4040

CMD ["/app/start.sh"]
