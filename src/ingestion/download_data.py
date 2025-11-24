import os
os.environ['KAGGLE_CONFIG_DIR'] = '/app/src/kaggle'
from kaggle.api.kaggle_api_extended import KaggleApi

print("=== Descargando datos desde Kaggle ===")

kaggle_json_path = '/app/src/kaggle/kaggle.json'

data_dir = "/app/data"
os.makedirs(data_dir, exist_ok=True)

dataset = "mysarahmadbhat/airbnb-listings-reviews"

api = KaggleApi()
api.authenticate()

api.dataset_download_files(dataset, path=data_dir, unzip=True)

print("Dataset descargado y descomprimido en:", data_dir)
