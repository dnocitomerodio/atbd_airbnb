#!/bin/bash

echo "==== Iniciando Hadoop ===="

if [ ! -d "$HADOOP_HOME/data/namenode/current" ]; then
    echo "Formateando NameNode..."
    $HADOOP_HOME/bin/hdfs namenode -format
fi

$HADOOP_HOME/sbin/start-dfs.sh
$HADOOP_HOME/sbin/start-yarn.sh

echo "Hadoop iniciado."

echo "==== Configurando Spark para Jupyter ===="
export PYSPARK_PYTHON=python3
export PYSPARK_DRIVER_PYTHON=jupyter
export PYSPARK_DRIVER_PYTHON_OPTS="lab --allow-root --ip=0.0.0.0 --NotebookApp.token='' --notebook-dir=/app/notebooks"

echo "==== Iniciando Spark con Jupyter Lab ===="
exec $SPARK_HOME/bin/pyspark

