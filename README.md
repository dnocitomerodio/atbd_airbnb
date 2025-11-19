# Proyecto Airbnb - Configuración de Entorno Hadoop y Spark en WSL

Este README explica cómo instalar, configurar y usar Hadoop 3.3.6 y Spark 3.4.3 en Ubuntu WSL en Windows.

# Requisitos previos: Windows 10 o 11 con WSL2 y Ubuntu 24.04 LTS instalada.

-Java 11 (openjdk-11-jdk) instalado en WSL.

-Conexión a internet para descargar Hadoop y Spark.

-Editor de texto: Visual Studio Code o similar.

# Actualizar paquetes

sudo apt update && sudo apt upgrade -y

# Instalar Git y wget

sudo apt install git wget nano tree -y

## Configuración y ejecución del entorno Hadoop + Spark

Este proyecto utiliza Hadoop 3.3.6 y Spark 3.4.3 sobre Ubuntu 24.04 en WSL2.

# Variables de entorno necesarias

Asegúrate de tener definidas las siguientes variables en tu ~/.bashrc:

# Java

export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export PATH=$JAVA_HOME/bin:$PATH

# Hadoop

export HADOOP_HOME=$HOME/hadoop
export PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH

# Spark

export SPARK_HOME=$HOME/spark
export PATH=$SPARK_HOME/bin:$PATH

# SSH para Hadoop

export HADOOP_SSH_OPTS="-i ~/.ssh/id_ed25519_hadoop -o StrictHostKeyChecking=no"

Luego recarga la configuración:

source ~/.bashrc

## Iniciar Hadoop

Asegúrate de que tu servidor SSH esté corriendo:

sudo service ssh start

# Inicia HDFS:

start-dfs.sh

# Inicia YARN:

start-yarn.sh

Verifica que todos los procesos de Hadoop estén activos:

jps

Deberías ver procesos como:

NameNode
SecondaryNameNode
DataNode
ResourceManager
NodeManager

# Detener Hadoop

stop-yarn.sh
stop-dfs.sh

# Iniciar Spark

Spark con Scala:

$SPARK_HOME/bin/spark-shell

Spark con Python (PySpark):

$SPARK_HOME/bin/pyspark

# Detener Spark

Simplemente sal de la consola de Spark con:

:quit en spark-shell

exit() en pyspark

