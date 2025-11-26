from pyspark.sql import SparkSession
from pyspark.sql.functions import col
import sys

def main():
    spark = SparkSession.builder \
        .appName("Airbnb Analyses") \
        .getOrCreate()
    
    print("Spark inicializado correctamente.")

    hdfs_base_path = "hdfs://localhost:9000/data/airbnb/"

    print("Cargando Listings.csv...")
    listings = spark.read.option("header", True).option("inferSchema", True).csv(f"{hdfs_base_path}Listings.csv")
    
    print("Cargando Reviews.csv...")
    reviews = spark.read.option("header", True).option("inferSchema", True).csv(f"{hdfs_base_path}Reviews.csv")

    print("Cargando diccionarios de datos (opcional)...")
    listings_dict = spark.read.option("header", True).csv(f"{hdfs_base_path}Listings_data_dictionary.csv")
    reviews_dict = spark.read.option("header", True).csv(f"{hdfs_base_path}Reviews_data_dictionary.csv")

    print("Convirtiendo columnas de precio a numérico...")
    listings = listings.withColumn("price", col("price").cast("double"))

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
