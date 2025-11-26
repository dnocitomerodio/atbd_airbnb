# 🏠 Proyecto Airbnb - Pipeline de Big Data con Hadoop y Spark (Dockerizado)

Este proyecto despliega un entorno completo de Big Data utilizando **Apache Hadoop (HDFS/YARN)** y **Apache Spark** dentro de contenedores Docker.

El sistema está automatizado para realizar la ingesta de datos, almacenamiento distribuido y procesamiento ETL automáticamente al iniciar el contenedor.

## 📋 Arquitectura del Proyecto

El entorno está construido sobre **Ubuntu 22.04** e incluye:

- **Hadoop 3.3.6:** Sistema de archivos distribuido (HDFS) y gestor de recursos (YARN).
- **Spark 3.5.1:** Motor de procesamiento de datos.
- **JupyterLab:** Entorno interactivo para análisis de datos (PySpark).
- **Python 3.10:** Con librerías `pyspark`, `pandas`, `kagglehub`.

### 🔄 Flujo de Automatización (`start.sh`)

Al iniciar el contenedor, ocurre lo siguiente automáticamente:

1.  **Arranque:** Se inician los servicios de SSH, HDFS y YARN.
2.  **Ingesta:** Se descargan los datasets de Airbnb desde Kaggle.
3.  **HDFS:** Se formatean los datos y se suben a `hdfs://localhost:9000/data/airbnb/`.
4.  **ETL:** Se ejecuta el script `run_analyses.py` que limpia los datos y los guarda en formato Parquet en `hdfs://localhost:9000/data/processed/`.
5.  **Interfaz:** Se lanza JupyterLab listo para usar.

---

## 🚀 Requisitos Previos

- **Docker** y **Docker Compose** instalados (Desktop en Windows/Mac o Engine en Linux).
- Una cuenta de Kaggle y un archivo `kaggle.json` (API Token).

---

## 🛠️ Instalación y Despliegue

### 1. Clonar el repositorio

```bash
git clone https://github.com/dnocitomerodio/atbd_airbnb.git
cd atbd_airbnb
```

### 2. Configurar Credenciales de Kaggle

Para que la descarga automática de datos funcione, necesitas colocar tu token de API de Kaggle en la ruta correcta dentro del proyecto.

1.  Descarga tu archivo `kaggle.json` desde tu perfil de Kaggle (Settings -> Create New Token).
2.  Coloca el archivo en la siguiente ruta del proyecto:
    `src/kaggle/kaggle.json`

> **Nota:** El `Dockerfile` se encarga de dar los permisos necesarios (chmod 600) a este archivo automáticamente.

### 3. Construir y Arrancar

Ejecuta los siguientes comandos para construir la imagen y levantar el entorno:

# 1. Construir la imagen Docker (necesario la primera vez o si modificas el Dockerfile/scripts)

```bash
docker-compose build
```

> **Nota:** La primera vez que ejecutes este comando, puede tardar varios minutos (llegando 45 minuotos si no dispones de buena conexión a internet) en descargar las imágenes de Hadoop y Spark, así como en instalar las dependencias de Python. Ten paciencia.

# 2. Levantar el contenedor

```bash
docker-compose up
```

---

## 🖥️ Acceso a las Interfaces

Una vez que el script de inicio haya terminado (verás en la terminal que se inicia JupyterLab), puedes acceder a los servicios a través de tu navegador:

| Servicio                 | URL                                                    | Descripción                                                                        |
| :----------------------- | :----------------------------------------------------- | :--------------------------------------------------------------------------------- |
| **JupyterLab**           | [http://localhost:8888/lab](http://localhost:8888/lab) | Entorno de desarrollo para Notebooks y scripts de PySpark.                         |
| **Hadoop NameNode**      | [http://localhost:9870](http://localhost:9870)         | Interfaz web de HDFS. Permite explorar archivos y ver el estado de los DataNodes.  |
| **YARN ResourceManager** | [http://localhost:8088](http://localhost:8088)         | Gestor de recursos. Permite monitorizar los trabajos (jobs) de Spark en ejecución. |

---

## 📂 Estructura de Datos en HDFS

Gracias al script de automatización (`start.sh` y `run_analyses.py`), los datos se organizan automáticamente en el sistema de archivos distribuido (HDFS) de la siguiente manera:

- **Datos Crudos (Raw):** `hdfs://localhost:9000/data/airbnb/`
  - Contiene los archivos CSV originales descargados de Kaggle (`Listings.csv`, `Reviews.csv`).
- **Datos Procesados (Processed):** `hdfs://localhost:9000/data/processed/`
  - Contiene los datos limpios y transformados en formato **Parquet** (columnar y optimizado para Big Data).
  - Carpetas: `/listings` y `/reviews`.

---

## 📁 Estructura del Repositorio

La organización de carpetas del proyecto es la siguiente:

```text
atbd_airbnb/
├── data/                  # Carpeta temporal para descargas locales (se ignora en git si es grande)
├── src/
│   ├── analyses/          # Scripts de procesamiento ETL (run_analyses.py)
│   ├── ingestion/         # Scripts de descarga de datos (download_data.py)
│   └── kaggle/            # Lugar para colocar tu kaggle.json
├── notebooks/             # Aquí se guardan tus Jupyter Notebooks (.ipynb)
├── Dockerfile             # Definición de la imagen con Ubuntu, Hadoop y Spark
├── docker-compose.yml     # Orquestación del contenedor
├── start.sh               # Script maestro de inicialización
└── README.md              # Documentación del proyecto
```

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
  hdfs dfs -ls /data/airbnb
  hdfs dfs -ls /data/processed
  ```
- **Arrancar consola de PySpark:** Para pruebas rápidas sin usar Jupyter.
  ```bash
  pyspark
  ```

---

## 🛑 Detener el entorno

Para apagar el contenedor, detener los servicios de Hadoop/Spark y liberar recursos de tu máquina:

1. Presiona Ctrl+C en la terminal donde se está ejecutando el log de Docker.

2. O bien, ejecuta el siguiente comando en una terminal separada (dentro de la carpeta del proyecto):

```bash
docker exec -it spark_container bash
```

---

## ⚠️ Solución de problemas comunes

- **Error kaggle.json not found:** Asegúrate de que el archivo está en src/kaggle/kaggle.json antes de hacer el build.

- **Contenedor se reinicia constantemente:** Revisa los logs con docker logs spark_container. Generalmente se debe a falta de memoria RAM asignada a Docker (Hadoop + Spark requieren al menos 4GB-6GB).

- **HDFS en Safe Mode:** El script start.sh intenta gestionar esto automáticamente. Si persiste, entra al contenedor y ejecuta:

```bash
hdfs dfsadmin -fs hdfs://localhost:9000 -safemode leave.
```

Autores: dnocitomerodio, gpb117 y xabier.losa Licencia: MIT
