FROM eclipse-temurin:11-jdk-focal

ENV HADOOP_VERSION=3.3.6
ENV SPARK_VERSION=3.5.1
ENV HADOOP_HOME=/opt/hadoop
ENV SPARK_HOME=/opt/spark
ENV PATH="$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$SPARK_HOME/bin:$PATH"
ENV KAGGLE_CONFIG_DIR=/app/src/kaggle

RUN apt-get update && apt-get install -y \
    curl wget python3 python3-pip nano sudo openssh-server rsync unzip && \
    rm -rf /var/lib/apt/lists/*

RUN curl -sSL https://downloads.apache.org/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz -o hadoop.tar.gz && \
    tar -xzf hadoop.tar.gz -C /opt && \
    mv /opt/hadoop-$HADOOP_VERSION $HADOOP_HOME && \
    rm hadoop.tar.gz

RUN curl -sSL https://archive.apache.org/dist/spark/spark-$SPARK_VERSION/spark-$SPARK_VERSION-bin-hadoop3.tgz -o spark.tgz && \
    tar -xzf spark.tgz -C /opt && \
    mv /opt/spark-$SPARK_VERSION-bin-hadoop3 $SPARK_HOME && \
    rm spark.tgz

RUN mkdir -p $HADOOP_HOME/data/namenode $HADOOP_HOME/data/datanode

RUN pip3 install --upgrade pip && \
    pip3 install --no-cache-dir jupyterlab pyspark pandas kagglehub kaggle

RUN adduser --disabled-password --gecos '' hdfs && \
    adduser --disabled-password --gecos '' yarn

RUN chown -R hdfs:hdfs $HADOOP_HOME

WORKDIR /app
RUN mkdir -p /app/notebooks /app/src /app/data
COPY src/ /app/src/
RUN chmod 600 /app/src/kaggle/kaggle.json && \
    chown -R hdfs:hdfs /app/src/kaggle

COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

EXPOSE 8888 9870 8088 7077 4040

USER hdfs

CMD ["/app/start.sh"]
