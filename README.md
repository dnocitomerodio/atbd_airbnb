# 🏠 Proyecto Airbnb - Cluster Big Data con Hadoop y Spark (Dockerizado)

Este proyecto despliega una arquitectura **Spark Standalone Cluster** completa utilizando contenedores Docker. Simula un entorno de producción real con nodos maestros y trabajadores distribuidos, diseñado para procesar grandes volúmenes de datos de Airbnb.

El sistema está automatizado para realizar la ingesta de datos, almacenamiento distribuido y procesamiento ETL automáticamente al iniciar el clúster.

## 📋 Arquitectura del Proyecto

El entorno despliega **5 contenedores** basados en Ubuntu 22.04 interconectados en una red interna:

1.  **`spark-master`**: Nodo Maestro. Ejecuta el **HDFS NameNode** y el **Spark Master**. Gestiona los recursos y la distribución de tareas.
2.  **`spark-worker-1` / `2` / `3`**: Nodos Trabajadores. Ejecutan **HDFS DataNodes** y **Spark Workers**. Aquí es donde se almacenan los datos y se realizan los cálculos.
3.  **`spark-client`**: Nodo Cliente. Contiene **JupyterLab** y los scripts de Python. Es el punto de entrada para los analistas de datos.

### 🔄 Flujo de Automatización (`start.sh`)

Al iniciar el clúster, ocurre lo siguiente automáticamente:

1.  **Orquestación:** Los nodos se reconocen entre sí y el Master toma el control.
2.  **Ingesta:** El nodo cliente descarga los datasets de Airbnb desde Kaggle.
3.  **HDFS:** Se suben los datos al sistema de archivos distribuido: `hdfs://spark-master:9000/data/airbnb/`.
4.  **ETL Distribuido:** Se ejecuta el script `run_analyses.py`. El Master reparte la carga de trabajo entre los 3 Workers para limpiar los datos y guardarlos en formato Parquet.
5.  **Interfaz:** Se lanza JupyterLab en el nodo cliente listo para usar.

---

## 🚀 Requisitos Previos

- **Docker** y **Docker Compose** instalados.
  - _Recomendado:_ Asignar al menos **6GB de RAM** a Docker Desktop para soportar los 5 contenedores.
- Una cuenta de Kaggle y un archivo `kaggle.json` (API Token).

---

## 🛠️ Instalación y Despliegue

### 1. Clonar el repositorio

```bash
git clone [https://github.com/dnocitomerodio/atbd_airbnb.git](https://github.com/dnocitomerodio/atbd_airbnb.git)
cd atbd_airbnb
```

### 2. Configurar Credenciales de Kaggle

Para que la descarga automática de datos funcione, necesitas colocar tu token de API de Kaggle en la ruta correcta dentro del proyecto.

1.  Descarga tu archivo `kaggle.json` desde tu perfil de Kaggle (Settings -> Create New Token).
2.  Coloca el archivo en la siguiente ruta del proyecto:
    `src/kaggle/kaggle.json`

> **Nota 1:** Por conveniencia he subido al proyecto mi propio `kaggle.json`. Se ruega a los usuarios con acceso a este repositorio privado que no lo usen para fines no relacionados con el proyecto.
> **Nota 2:** El `Dockerfile` se encarga de dar los permisos necesarios (chmod 600) a este archivo automáticamente.

### 3. Construir y Arrancar

Ejecuta los siguientes comandos para construir la imagen y levantar el entorno:

**1. Construir las imágenes** (Necesario la primera vez):

```bash
docker-compose build
```

> **Nota:** La primera vez que ejecutes este comando, puede tardar varios minutos (llegando a 45 minutos si no dispones de buena conexión a internet) en descargar las imágenes de Hadoop y Spark, así como en instalar las dependencias de Python. Ten paciencia.

# 2. Levantar el contenedor

```bash
docker-compose up
```

---

## 🖥️ Acceso a las Interfaces

Una vez arrancado el sistema, se puede monitorear el clúster desde tu navegador:

| Servicio            | URL                                                    | Descripción                                                                                   |
| :------------------ | :----------------------------------------------------- | :-------------------------------------------------------------------------------------------- |
| **JupyterLab**      | [http://localhost:8888/lab](http://localhost:8888/lab) | Entorno de desarrollo (Notebooks). Tu zona de trabajo en el nodo cliente.                     |
| **Spark Master UI** | [http://localhost:8080](http://localhost:8080)         | Panel de control del Clúster. Muestra los **3 Workers** conectados y las tareas en ejecución. |
| **Hadoop NameNode** | [http://localhost:9870](http://localhost:9870)         | Explorador de archivos HDFS y estado del almacenamiento.                                      |

---

## 🐍 Guía de Uso para Analistas (Python/PySpark)

Para aprovechar la potencia del clúster distribuido, hay que configurar la `SparkSession` correctamente en los Notebooks para delegar el trabajo al Master:

```python
from pyspark.sql import SparkSession

# Conectar al master del cluster
spark = SparkSession.builder \
    .appName("MiAnalisis") \
    .master("spark://spark-master:7077") \
    .getOrCreate()

# Leer datos desde HDFS en sistema distribuido
df = spark.read.parquet("hdfs://spark-master:9000/data/processed/listings")

# Datos crudos del csv solo si necesitas la fuente original (si no estaís obligados no lo hagaís que os conozco):
df_raw = spark.read.csv("hdfs://spark-master:9000/data/airbnb/Listings.csv", header=True, inferSchema=True)
```

---

### 2. Estructura de Datos en HDFS

````markdown
## 📂 Estructura de Datos en HDFS

Los datos se encuentran distribuidos en los nodos del clúster, accesibles vía `hdfs://spark-master:9000/`:

- **Datos Crudos:** `/data/airbnb/` (CSV originales).
- **Datos Procesados:** `/data/processed/` (Formato Parquet optimizado).

---

## 📁 Estructura del Repositorio

```text
atbd_airbnb/
├── data/                  # Carpeta temporal para descargas locales
├── src/
│   ├── analyses/          # Scripts de procesamiento ETL (run_analyses.py)
│   ├── ingestion/         # Scripts de descarga de datos (download_data.py)
│   └── kaggle/            # Credenciales (kaggle.json)
├── notebooks/             # Tus Jupyter Notebooks (.ipynb)
├── Dockerfile             # Definición de la imagen base
├── docker-compose.yml     # Definición del clúster (Master, Workers, Client)
├── start.sh               # Script maestro de inicialización y roles
└── README.md              # Documentación del proyecto
```
````

---

## 🔧 Comandos Útiles y Debugging

Si necesitas interactuar directamente con el entorno, ver logs o ejecutar comandos de Hadoop manualmente, puedes acceder a la terminal del contenedor.

### 1. Acceder al contenedor

Abre una nueva terminal (mientras el contenedor sigue corriendo) y ejecuta:

```bash
docker exec -it spark_container bash
```

### 2. Comandos útiles dentro del contenedor

Una vez dentro del contenedor, puedes usar estos comandos:

- **Verificar procesos activos (JPS):** Comprueba que los demonios de Hadoop (NameNode, DataNode, etc.) están vivos.
  ```bash
  jps
  ```
- **Listar archivos en HDFS:** Para ver qué se ha subido o procesado.

  ```bash
  # Ver datos crudos
  hdfs dfs -ls /data/airbnb

  # Ver datos procesados
  hdfs dfs -ls /data/processed
  ```

- **Arrancar consola de PySpark (Modo Cluster):** Para probar la conexión con el Master y los Workers desde la terminal.
  ```bash
  pyspark --master spark://spark-master:7077
  ```

---

## 🛑 Detener el entorno

Para apagar el contenedor, detener los servicios de Hadoop/Spark y liberar recursos de tu máquina:

1. Presiona Ctrl+C en la terminal donde se está ejecutando el log de Docker.

2. O bien, ejecuta el siguiente comando en una terminal separada (dentro de la carpeta del proyecto):

```bash
docker-compose down
```

> **Nota:** Si quieres borrar los datos y empezar de cero (limpieza total), usa docker-compose down -v.

---

## ⚠️ Solución de problemas comunes

- **Error kaggle.json not found:** Asegúrate de que el archivo está en src/kaggle/kaggle.json antes de hacer el build.

- **Contenedores se mueren (Exit Code 137):** Significa falta de memoria RAM. Hay que aumenta la memoria de Docker Desktop a 6GB o 8GB.

- **HDFS en Safe Mode:** El script start.sh intenta gestionar esto automáticamente. Si persiste, entra al contenedor y ejecuta:

```bash
hdfs dfsadmin -fs hdfs://localhost:9000 -safemode leave.
```

Autores: dnocitomerodio, gpb117 y xabier.losa Licencia: MIT
