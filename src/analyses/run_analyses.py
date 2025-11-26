from pyspark.sql import SparkSession
from pyspark.sql.functions import col, regexp_replace
import sys

def main():
    spark = SparkSession.builder \
        .appName("Airbnb Analyses") \
        .getOrCreate()
    
    print("Spark inicializado correctamente.")

    hdfs_base_path = "hdfs://localhost:9000/data/airbnb/"

    print("Cargando Listings.csv con opciones avanzadas...")
    listings = spark.read \
        .option("header", True) \
        .option("inferSchema", True) \
        .option("quote", "\"") \
        .option("escape", "\"") \
        .option("multiLine", True) \
        .csv(f"{hdfs_base_path}Listings.csv")
    
    print("Cargando Reviews.csv...")
    reviews = spark.read \
        .option("header", True) \
        .option("inferSchema", True) \
        .option("quote", "\"") \
        .option("escape", "\"") \
        .option("multiLine", True) \
        .csv(f"{hdfs_base_path}Reviews.csv")

    print("Cargando diccionarios de datos (opcional)...")
    listings_dict = spark.read.option("header", True).csv(f"{hdfs_base_path}Listings_data_dictionary.csv")
    reviews_dict = spark.read.option("header", True).csv(f"{hdfs_base_path}Reviews_data_dictionary.csv")

    print("Limpiando y convirtiendo columnas de precio a numérico...")
    if "price" in listings.columns:
        listings = listings.withColumn("price", regexp_replace(col("price"), "[\$,]", "").cast("double"))
    else:
        print("ADVERTENCIA: La columna 'price' no se encontró. Verifica el parseo del CSV.")

    listings.createOrReplaceTempView("listings")
    reviews.createOrReplaceTempView("reviews")

    print("Vistas temporales creadas: listings, reviews")

    processed_path = "hdfs:///data/processed/"
    print(f"Guardando DataFrames limpios en {processed_path}")
    
    listings.write.mode("overwrite").parquet(f"{processed_path}listings")
    reviews.write.mode("overwrite").parquet(f"{processed_path}reviews")

    print("Datos procesados y guardados correctamente.")

    spark.stop()
    print("Spark detenido.")

if __name__ == "__main__":
    main()