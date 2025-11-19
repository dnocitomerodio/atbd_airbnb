FROM openjdk:11-jdk-slim

RUN apt-get update && \
    apt-get install -y python3 python3-pip wget curl vim ssh && \
    rm -rf /var/lib/apt/lists/*

RUN pip3 install pyspark pandas matplotlib

WORKDIR /app
COPY scripts/ scripts/
COPY data/ data/
COPY notebooks/ notebooks/

EXPOSE 4040

CMD ["/bin/bash"]
