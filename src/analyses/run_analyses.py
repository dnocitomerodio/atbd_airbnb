from pyspark.sql import SparkSession
from pyspark.sql.functions import col, regexp_replace
import sys

def main():
    spark = SparkSession.builder \
        .appName("Airbnb Analyses") \
        .master("spark://spark-master:7077") \
        .getOrCreate()
    
    print("Spark distribuido inicializado correctamente.")

    hdfs_base_path = "hdfs://spark-master:9000/data/airbnb/"
    processed_path = "hdfs://spark-master:9000/data/processed/"

    print("Cargando Listings.csv...")
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

    print("Limpiando...")
    if "price" in listings.columns:
        listings = listings.withColumn("price", regexp_replace(col("price"), "[\$,]", "").cast("double"))

    listings.createOrReplaceTempView("listings")
    reviews.createOrReplaceTempView("reviews")

    print(f"Guardando DataFrames limpios en {processed_path}")
    listings.write.mode("overwrite").parquet(f"{processed_path}listings")
    reviews.write.mode("overwrite").parquet(f"{processed_path}reviews")

    print("Datos procesados y guardados correctamente.")
    spark.stop()

if __name__ == "__main__":
    main()