#!/bin/bash
set -e

export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop
export PATH="$JAVA_HOME/bin:$PATH"
export SPARK_HOME=/opt/spark
PY4J_ZIP=$(ls $SPARK_HOME/python/lib/py4j-*-src.zip | head -n 1)
export PYTHONPATH=$SPARK_HOME/python:$PY4J_ZIP:$PYTHONPATH
export SPARK_NO_DAEMONIZE=true

CFG_DIR="$HADOOP_HOME/etc/hadoop"

echo "Configurando core-site.xml..."
cat > "$CFG_DIR/core-site.xml" <<EOF
<?xml version="1.0"?>
<configuration>
  <property>
    <name>fs.defaultFS</name>
    <value>hdfs://spark-master:9000</value>
  </property>
</configuration>
EOF

echo "Configurando hdfs-site.xml..."
cat > "$CFG_DIR/hdfs-site.xml" <<EOF
<?xml version="1.0"?>
<configuration>
  <property>
    <name>dfs.replication</name>
    <value>2</value>
  </property>
  <property>
    <name>dfs.namenode.name.dir</name>
    <value>file:///opt/hadoop/data/namenode</value>
  </property>
  <property>
    <name>dfs.datanode.data.dir</name>
    <value>file:///opt/hadoop/data/datanode</value>
  </property>
  <property>
    <name>dfs.webhdfs.enabled</name>
    <value>true</value>
  </property>
  <property>
    <name>dfs.permissions.enabled</name>
    <value>false</value>
  </property>
</configuration>
EOF

if ! grep -q "export JAVA_HOME" "$CFG_DIR/hadoop-env.sh"; then
  echo -e "\nexport JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64" >> "$CFG_DIR/hadoop-env.sh"
fi

if [ "$SPARK_ROLE" == "master" ]; then
    echo ">>> ROL: MASTER (HDFS NameNode + Spark Master)"
    
    if [ ! -f "$HADOOP_HOME/data/namenode/current/VERSION" ]; then
        echo "Formateando NameNode..."
        hdfs namenode -format -force
    fi
    echo "Iniciando NameNode..."
    hdfs --daemon start namenode
    
    echo "Iniciando Spark Master..."
    /opt/spark/bin/spark-class org.apache.spark.deploy.master.Master --host spark-master --port 7077 --webui-port 8080

elif [ "$SPARK_ROLE" == "worker" ]; then
    echo ">>> ROL: WORKER (HDFS DataNode + Spark Worker)"
    
    sleep 5
    echo "Iniciando DataNode..."
    hdfs --daemon start datanode
    
    echo "Iniciando Spark Worker conectando a $SPARK_MASTER_URL..."
    /opt/spark/bin/spark-class org.apache.spark.deploy.worker.Worker $SPARK_MASTER_URL

elif [ "$SPARK_ROLE" == "client" ]; then
    echo ">>> ROL: CLIENTE (Jupyter + Scripts)"
    
    echo "Esperando a HDFS..."
    sleep 15
    until hdfs dfsadmin -fs hdfs://spark-master:9000 -safemode wait; do
        echo "Esperando al NameNode..."
        sleep 5
    done

    echo "=== Descargando datos ==="
    python3 /app/src/ingestion/download_data.py || echo "Aviso: Descarga omitida o fallida"

    echo "=== Subiendo a HDFS ==="
    hdfs dfs -fs hdfs://spark-master:9000 -mkdir -p /data/airbnb || true
    
    if [ -d "/app/data/Airbnb Data" ]; then
        mv "/app/data/Airbnb Data" /app/data/airbnb_clean
    fi

    if [ -d "/app/data/airbnb_clean" ]; then
        hdfs dfs -fs hdfs://spark-master:9000 -put -f /app/data/airbnb_clean/* /data/airbnb/ || true
    elif [ -d "/app/data" ]; then
         find /app/data -name "*.csv" -exec hdfs dfs -fs hdfs://spark-master:9000 -put -f {} /data/airbnb/ \; || true
    fi

    echo "=== Ejecutando Analíticas ETL ==="
    python3 /app/src/analyses/run_analyses.py || echo "Analíticas terminadas"

    echo "=== Lanzando JupyterLab ==="
    export PYSPARK_DRIVER_PYTHON=jupyter
    export PYSPARK_DRIVER_PYTHON_OPTS="lab --allow-root --no-browser --ip=0.0.0.0 --NotebookApp.token='' --notebook-dir=/app/notebooks"
    export SPARK_DRIVER_HOST=spark-client
    
    exec pyspark --master spark://spark-master:7077

else
    echo "Rol desconocido: $SPARK_ROLE"
    exit 1
fi