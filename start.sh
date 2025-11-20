#!/bin/bash
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export HADOOP_HOME=/app/hadoop
export SPARK_HOME=/app/spark
export PATH=$JAVA_HOME/bin:$HADOOP_HOME/bin:$SPARK_HOME/bin:$PATH

export HADOOP_SSH_OPTS="-o StrictHostKeyChecking=no"

echo "Descargando datasets desde Kagglehub..."
python3 - <<EOF
import kagglehub

# Cambia por el dataset que vayas a usar
dataset_path = kagglehub.dataset_download("mysarahmadbhat/airbnb-listings-reviews")
print("Datasets descargados en:", dataset_path)
EOF

echo "Iniciando Hadoop DFS y YARN..."
start-dfs.sh
start-yarn.sh

echo "Iniciando Jupyter Notebook..."
jupyter notebook --ip=0.0.0.0 --port=8888 --allow-root --notebook-dir=/app/notebooks
