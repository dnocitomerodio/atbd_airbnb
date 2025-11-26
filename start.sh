#!/bin/bash
set -e

echo "=== Iniciando SSH ==="
sudo service ssh start

export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop
export PATH="$JAVA_HOME/bin:$PATH"

export SPARK_HOME=/opt/spark
export PYTHONPATH=$SPARK_HOME/python:$SPARK_HOME/python/lib/py4j-0.10.9.7-src.zip:$PYTHONPATH
export PYSPARK_PYTHON=python3
export PYSPARK_DRIVER_PYTHON=python3

CFG_DIR="$HADOOP_HOME/etc/hadoop"

echo "=== Verificando/creando configs de Hadoop ==="

if [ ! -s "$CFG_DIR/core-site.xml" ]; then
  cat > "$CFG_DIR/core-site.xml" <<'EOF'
<?xml version="1.0"?>
<configuration>
  <property>
    <name>fs.defaultFS</name>
    <value>hdfs://localhost:9000</value>
  </property>
</configuration>
EOF
  echo "Wrote core-site.xml"
fi

if [ ! -s "$CFG_DIR/hdfs-site.xml" ]; then
  cat > "$CFG_DIR/hdfs-site.xml" <<'EOF'
<?xml version="1.0"?>
<configuration>
  <property>
    <name>dfs.replication</name>
    <value>1</value>
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
</configuration>
EOF
  echo "Wrote hdfs-site.xml"
fi

if [ ! -s "$CFG_DIR/yarn-site.xml" ]; then
  cat > "$CFG_DIR/yarn-site.xml" <<'EOF'
<?xml version="1.0"?>
<configuration>
  <property>
    <name>yarn.nodemanager.aux-services</name>
    <value>mapreduce_shuffle</value>
  </property>
  <property>
    <name>yarn.nodemanager.env-whitelist</name>
    <value>JAVA_HOME,HADOOP_COMMON_HOME,HADOOP_HDFS_HOME,HADOOP_CONF_DIR,CLASSPATH_PREPEND_DISTCACHE,HADOOP_YARN_HOME,HADOOP_MAPRED_HOME</value>
  </property>
</configuration>
EOF
  echo "Wrote yarn-site.xml"
fi

if ! grep -q "export JAVA_HOME" "$CFG_DIR/hadoop-env.sh"; then
  echo -e "\nexport JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64" >> "$CFG_DIR/hadoop-env.sh"
  echo "Appended JAVA_HOME to hadoop-env.sh"
fi

echo "=== Limpieza de directorios temporales de Hadoop ==="
rm -rf /tmp/hadoop-* || true

echo "=== Descargando datos con KaggleHub ==="
python3 /app/src/ingestion/download_data.py || true

echo "=== Verificando NameNode ==="
if [ ! -d "$HADOOP_HOME/data/namenode/current" ]; then
    echo "Formateando NameNode..."
    hdfs namenode -format -force
else
    echo "NameNode ya formateado."
fi

echo "=== Iniciando HDFS y YARN ==="
start-dfs.sh
start-yarn.sh

echo "=== Esperando que HDFS salga del Safe Mode ==="
until hdfs dfs -ls / >/dev/null 2>&1; do 
  echo "Esperando a NameNode..."
  sleep 2
done

echo "Esperando a salir de Safe Mode..."
hdfs dfsadmin -safemode wait

echo "HDFS accesible y listo para escritura."

echo "=== Subiendo datos al HDFS ==="
hdfs dfs -mkdir -p /data/airbnb || true

if [ -d "/app/data/Airbnb Data" ]; then
    echo "Subiendo archivos..."
    hdfs dfs -put -f "/app/data/Airbnb Data/"* /data/airbnb/ || true
else
    echo "ADVERTENCIA: No se encontró la carpeta '/app/data/Airbnb Data'. Verifica tu script de descarga."
fi

echo "=== Ejecutando PySpark analyses ==="
python3 /app/src/analyses/run_analyses.py || echo "Analíticas terminadas con errores no fatales"

echo "=== Lanzando PySpark + JupyterLab ==="
export PYSPARK_DRIVER_PYTHON=jupyter
export PYSPARK_DRIVER_PYTHON_OPTS="lab --allow-root --no-browser --ip=0.0.0.0 --NotebookApp.token='' --notebook-dir=/app/notebooks"

exec pyspark