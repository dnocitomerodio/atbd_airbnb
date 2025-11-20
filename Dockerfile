FROM eclipse-temurin:11-jdk-focal

RUN apt-get update && \
    apt-get install -y python3 python3-pip wget curl vim ssh unzip && \
    rm -rf /var/lib/apt/lists/*

RUN pip3 install pyspark pandas matplotlib kaggle jupyter kagglehub

RUN mkdir -p /app/hadoop /app/scripts /app/notebooks /app/data /app/results

RUN wget https://downloads.apache.org/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz && \
    tar -xvzf hadoop-3.3.6.tar.gz && \
    mv hadoop-3.3.6 /app/hadoop && \
    rm hadoop-3.3.6.tar.gz


WORKDIR /app

ENV HADOOP_HOME=/app/hadoop
ENV PATH="$HADOOP_HOME/bin:$PATH"
COPY hadoop/ /app/hadoop/
COPY scripts/ /app/scripts/
COPY notebooks/ /app/notebooks/
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

EXPOSE 4040
EXPOSE 8888

CMD ["/bin/bash", "/app/start.sh"]
