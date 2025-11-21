#!/bin/bash

echo "Iniciando Hadoop..."
$HADOOP_HOME/bin/hdfs namenode -format
$HADOOP_HOME/sbin/start-dfs.sh
$HADOOP_HOME/sbin/start-yarn.sh

echo "Iniciando Jupyter..."
jupyter lab --allow-root --ip=0.0.0.0 --NotebookApp.token=''
